use strictures 1;
use Test::More skip_all => 'TODO';

use HTML::Zoom::Parser::HH5P;
use HTML::Zoom::Producer::BuiltIn;
use HTML::Zoom::SelectorParser;
use HTML::Zoom::FilterBuilder;
use HTML::Zoom::FilterStream;

my $tmpl = <<END;
<body>
  <div class="main">
    <span class="hilight name">Bob</span>
    <span class="career">Builder</span>
    <hr />
  </div>
</body>
END

sub src_stream { HTML::Zoom::Parser::HH5P->new->html_to_stream($tmpl); }

sub html_sink { HTML::Zoom::Producer::BuiltIn->new->html_from_stream($_[0]) }

my $fb = HTML::Zoom::FilterBuilder->new;

my $sp = HTML::Zoom::SelectorParser->new;

sub filter {
  my ($stream, $sel, $cb) = @_;
  return HTML::Zoom::FilterStream->new({
    stream => $stream,
    match => $sp->parse_selector($sel),
    filter => do { local $_ = $fb; $cb->($fb) }
  });
}

sub run_for (&;$) {
  my $cb = shift;
  (html_sink
    (filter
      src_stream,
      (shift or '.main'),
      $cb
    )
  )
}

my ($expect, @ev);

($expect = $tmpl) =~ s/class="main"/class="foo"/;

is(
  run_for { $_->set_attribute({ name => 'class', value => 'foo' }) },
  $expect,
  'set attribute on existing attribute'
);

($expect = $tmpl) =~ s/class="main"/class="main" foo="bar"/;

is(
  run_for { $_->set_attribute({ name => 'foo', value => 'bar' }) },
  $expect,
  'set attribute on non existing attribute'
);

($expect = $tmpl) =~ s/class="main"/class="main foo"/;

is(
  run_for { $_->add_to_attribute({ name => 'class', value => 'foo' }) },
  $expect,
  'add attribute on existing attribute'
);

($expect = $tmpl) =~ s/class="main"/class="main" foo="bar"/;

is(
  run_for { $_->add_to_attribute({ name => 'foo', value => 'bar' }) },
  $expect,
  'add attribute on non existing attribute'
);

($expect = $tmpl) =~ s/ class="main"//;

is(
  run_for { $_->remove_attribute({ name => 'class' }) },
  $expect,
  'remove attribute on existing attribute'
);

is(
  run_for { $_->remove_attribute({ name => 'foo' }) },
  $tmpl,
  'remove attribute on non existing attribute'
);

($expect = $tmpl) =~ s/ class="main"//;

is(
  run_for {
      $_->transform_attribute({
          name => 'class',
          code => sub {
              my $a = shift;
              return if $a eq 'main';
              return $a;
          },
      })
  },
  $expect,
  'transform_attribute deletes the attr if code returns undef',
  );

($expect = $tmpl) =~ s/ class="main"/ class="moan"/;

is(
  run_for {
      $_->transform_attribute({
          name => 'class',
          code => sub {
              ( my $b = shift ) =~ s/main/moan/;
              $b
          },
      })
  },
  $expect,
  'transform_attribute transforms something',
  );

($expect = $tmpl) =~ s/ class="main"/ class="main" noggin="zonk"/;

is(
  run_for {
      $_->transform_attribute({
          name => 'noggin',
          code => sub { 'zonk' },
      })
  },
  $expect,
  'transform_attribute adds attribute if not there before',
  );

is(
  run_for {
      $_->transform_attribute({
          name => 'noggin',
          code => sub { },
      })
  },
  $tmpl,
  'transform_attribute on nonexistent att does not add it if code returns undef',
  );


($expect = $tmpl) =~ s/(?=<div)/O HAI/;

my $ohai = [ { type => 'TEXT', raw => 'O HAI' } ];

is(
  run_for { $_->add_before($ohai) },
  $expect,
  'add_before ok'
);

($expect = $tmpl) =~ s/(?<=<\/div>)/O HAI/;

is(
  run_for { $_->add_after($ohai) },
  $expect,
  'add_after ok'
);

($expect = $tmpl) =~ s/(?<=class="main">)/O HAI/;

is(
  run_for { $_->prepend_content($ohai) },
  $expect,
  'prepend_content ok'
);

($expect = $tmpl) =~ s/<hr \/>/<hr>O HAI<\/hr>/;

is(
  (run_for { $_->prepend_content($ohai) } 'hr'),
  $expect,
  'prepend_content ok with in place close'
);

is(
  run_for { $_->replace($ohai) },
'<body>
  O HAI
</body>
',
  'replace ok'
);

@ev = ();

is(
  run_for { $_->collect({ into => \@ev }) },
  '<body>
  
</body>
',
  'collect removes without passthrough'
);

is(
  HTML::Zoom::Producer::BuiltIn->html_from_events(\@ev),
  '<div class="main">
    <span class="hilight name">Bob</span>
    <span class="career">Builder</span>
    <hr />
  </div>',
  'collect collected right events'
);

@ev = ();

is(
  run_for { $_->collect({ into => \@ev, content => 1 }) },
  '<body>
  <div class="main"></div>
</body>
',
  'collect w/content removes correctly'
);

is(
  HTML::Zoom::Producer::BuiltIn->html_from_events(\@ev),
  '
    <span class="hilight name">Bob</span>
    <span class="career">Builder</span>
    <hr />
  ',
  'collect w/content collects correctly'
);

is(
  run_for { $_->replace($ohai, { content => 1 }) },
  '<body>
  <div class="main">O HAI</div>
</body>
',
  'replace w/content'
);

($expect = $tmpl) =~ s/(?=<\/div>)/O HAI/;

is(
  run_for { $_->append_content($ohai) },
  $expect,
  'append content ok'
);

my $r_content = sub { my $r = shift; sub { $_->replace($r, { content => 1 }) } };

is(
  run_for {
    $_->repeat(
      [
        sub {
          filter
            filter($_ => '.name' => $r_content->('mst'))
            => '.career' => $r_content->('Chainsaw Wielder')
        },
        sub {
          filter
            filter($_ => '.name' => $r_content->('mdk'))
            => '.career' => $r_content->('Adminion')
        },
      ]
    )
  },
  q{<body>
  <div class="main">
    <span class="hilight name">mst</span>
    <span class="career">Chainsaw Wielder</span>
    <hr />
  </div><div class="main">
    <span class="hilight name">mdk</span>
    <span class="career">Adminion</span>
    <hr />
  </div>
</body>
},
  'repeat ok'
);

is(
  run_for {
    $_->repeat_content(
      [
        sub {
          filter
            filter($_ => '.name' => $r_content->('mst'))
            => '.career' => $r_content->('Chainsaw Wielder')
        },
        sub {
          filter
            filter($_ => '.name' => $r_content->('mdk'))
            => '.career' => $r_content->('Adminion')
        },
      ]
    )
  },
  q{<body>
  <div class="main">
    <span class="hilight name">mst</span>
    <span class="career">Chainsaw Wielder</span>
    <hr />
  
    <span class="hilight name">mdk</span>
    <span class="career">Adminion</span>
    <hr />
  </div>
</body>
},
  'repeat_content ok'
);

is(
  run_for {
    my @between;
    $_->repeat_content(
      [
        sub {
          HTML::Zoom::ArrayStream->new({ array => [
            (filter
              filter($_ => '.name' => $r_content->('mst'))
              => '.career' => $r_content->('Chainsaw Wielder')),
            HTML::Zoom::ArrayStream->new({ array => \@between })
          ] })->flatten
        },
        sub {
          filter
            filter($_ => '.name' => $r_content->('mdk'))
            => '.career' => $r_content->('Adminion')
        },
      ],
      { filter => sub {
          filter $_[0] => 'hr' => sub { $_->collect({ into => \@between }) }
        }
      }
    )
  },
  q{<body>
  <div class="main">
    <span class="hilight name">mst</span>
    <span class="career">Chainsaw Wielder</span>
    <hr />
    <span class="hilight name">mdk</span>
    <span class="career">Adminion</span>
    
  </div>
</body>
},
  'repeat_content with filter ok'
);

is(
  run_for {
    my @between;
    $_->repeat_content(
      [
        sub {
          filter
            filter($_ => '.name' => $r_content->('mst'))
            => '.career' => $r_content->('Chainsaw Wielder')
        },
        sub {
          filter
            filter($_ => '.name' => $r_content->('mdk'))
            => '.career' => $r_content->('Adminion')
        },
      ],
      { repeat_between => 'hr' }
    )
  },
  q{<body>
  <div class="main">
    <span class="hilight name">mst</span>
    <span class="career">Chainsaw Wielder</span>
    <hr />
    <span class="hilight name">mdk</span>
    <span class="career">Adminion</span>
    
  </div>
</body>
},
  'repeat_content using repeat_between ok'
);

done_testing;
