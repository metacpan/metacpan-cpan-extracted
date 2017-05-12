package Evo::Export;
use Evo '::Meta';


my $META = Evo::Export::Meta->find_or_bind_to(__PACKAGE__);

sub install_in ($me, $dest, $from, @list) {
  Evo::Export::Meta->find_or_bind_to($from)->install($dest, @list);
}

sub Export ($pkg, $code, $name, $as = $name) : Attr {
  $name or (undef, $name) = Evo::Lib::Bare::code2names($code);
  Evo::Export::Meta->find_or_bind_to($pkg)->export_code($as, $code);
}

sub ExportGen ($pkg, $gen, $name, $as = $name) : Attr {
  $name or (undef, $name) = Evo::Lib::Bare::code2names($gen);
  Evo::Export::Meta->find_or_bind_to($pkg)->export_gen($as, $gen);
}

sub import ($self, @list) {
  my $dest = scalar caller;
  Evo::Export::Meta->find_or_bind_to($dest);
  @list = ('*') unless @list;
  Evo::Export::Meta->find_or_bind_to($self)->install($dest, @list);
}

sub _import ($self, @list) : Export(import) {
  my $dest = scalar caller;
  Evo::Export::Meta->find_or_bind_to($self)->install($dest, @list);
}


sub EXPORT ($me, $dest) : ExportGen {
  sub {
    Evo::Export::Meta->find_or_bind_to($dest);
  };
}

sub import_all ($exporter, @list) : Export {
  @list = ('*') unless @list;
  Evo::Export::Meta->find_or_bind_to($exporter)->install(scalar caller, @list);
}

sub export_gen ($me, $dst) : ExportGen {
  sub ($name, $gen) {
    Evo::Export::Meta->find_or_bind_to($dst)->export_gen($name, $gen);
  };
}

sub export_code ($me, $dst) : ExportGen {
  sub ($name, $fn) {
    Evo::Export::Meta->find_or_bind_to($dst)->export_code($name, $fn);
  };
}

sub export ($me, $dst) : ExportGen {
  sub { Evo::Export::Meta->find_or_bind_to($dst)->export($_) for @_ }
}

sub export_proxy ($me, $dst) : ExportGen {
  sub ($origpkg, @list) {
    Evo::Export::Meta->find_or_bind_to($dst)->export_proxy($origpkg, @list);
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Export

=head1 VERSION

version 0.0403

=head1 DESCRIPTION

Standart L<Exporter> wasn't good enough for me, so I've written a new one from the scratch

=head1 SYNOPSYS

  package My::Lib;
  use Evo '-Export *', -Loaded;

  # export foo, other as bar
  sub foo : Export        { say 'foo' }
  sub other : Export(bar) { say 'bar' }

  # test.pl
  package main;
  use Evo 'My::Lib *';
  foo();
  bar();

=head1 IMPORTING

  use Evo;
  use Evo 'Evo::Eval eval_try';
  use Evo '-Promise promise deferred';

For convenient, you can load all above in one line (divide by C<,> or C<;>)

  use Evo '-Eval eval_try; -Promise promise deferred';
  use Evo '-Eval eval_try, -Promise promise deferred';

C<*> means load all. C<-> is a shortcut. See L<Evo/"shortcuts>

=head2 what to import and how

You can rename subroutines to avoid method clashing

  # import promise as prm
  use Evo '-Promise promise:prm';

You can use C<*> with exclude C<-> for convinient, use whitespace as a delimiter

  # import all except "deferred"
  use Evo '-Promise * -deferred';

If one name clashes with yours, you can import all except that name and import
renamed version of that name

  # import all as is but only deferred will be renamed to "renamed_deferred"
  use Evo '-Promise * -deferred deferred:renamed_deferred';

=head1 EXPORTING

Firstly you need to load L<Evo::Export> with C<import> (or C<*>). This will import C<import> method:

  use Evo '-Export *';
  use Evo '-Export import';

By default, C<use Your::Module;>, without arguments will import nothing. You can change this behaviour to export all without arguments

  use Evo '-Export import_all:import';
  use Evo '-Export * -import import_all:import';

Using attribute C<Export>

  package My::Lib;
  use Evo '-Export *'; # or use Evo::Export 'import';
  use Evo -Loaded;

  sub foo : Export { say 'foo' }

  package main;
  use Evo 'My::Lib foo';
  foo();

Pay attention that module should either import C<import>, or call C<Evo::Export/install> directly (see example below) from C<import> method

You can export with another name

  # export as bar
  sub foo : Export(bar) {say 'foo'}

(EXPERIMENTAL) Using attribte C<ExportGen>

  package My::Lib;
  use Evo '-Export *; -Loaded';

  sub bar ($me, $dest) : ExportGen {
    say qq{"$dest" requested "bar" exported by "$me"};
    return sub { say "$me-$dest-bar" };
  }

  package main;
  use Evo;
  My::Lib->import('*');
  bar();

=head1 INSTALLING DIRECTLY

If you want to write your own C<import> method, do it this way:

  package My::Lib;
  use Evo -Export;    # don't import "import"
  use Evo -Loaded;

  sub import ($self, @list) {
    my $dest = scalar caller;
    Evo::Export->install_in($dest, $self, @list ? @list : ('*'));    # force to install all
  }
  sub foo : Export { say 'foo' }


  package main;
  use Evo 'My::Lib';
  foo();

=head4 export;

C<Export> signature is more preffered way, but if you wish

  # export foo
  export 'foo';

  # export "foo" under name "bar"
  export 'foo:bar';

Trying to export not existing subroitine will cause an exception

=head4 export_code

Export function, that won't be available in the source class

  # My::Lib now exports foo, but My::Lib::foo doesn't exist
  export_code foo => sub { say "hello" };

=head4 export_proxy

  # reexport all from My::Other
  export_proxy 'My::Other', '*';


  # reexport "foo" from My::Other
  export_proxy 'My::Other', 'foo';

  # reexport "foo" from My::Other as "bar"
  export_proxy 'My::Other', 'foo:bar';

=head4 export_gen (EXPERIMENTAL)

  package My::Lib;
  use Evo '-Export *; -Loaded';

  export_gen foo => sub ($me, $dest) {
    say qq{"$dest" requested "foo" exported by "$me"};
    sub {say "hello, $dest"};
  };


  package main;
  use Evo;
  My::Lib->import('*');
  foo();

Very powefull and most exciting feature. C<Evo::Export> exports generators, that produces subroutines. Consider it as a 3nd dimension in 3d programming.
Better using with C<ExportGen> attribute

=head4 EXPORT

This method returns a bound instance of L<Evo::Export::Meta>, which is stored in package's C<$EVO_EXPORT_META> variable.
Also a cache for generated export is stored in class'es C<$EVO_EXPORT_CACHE> variable

  use Evo;
  {

    package My::Lib;
    use Evo '-Export *', -Loaded;
    sub foo : Export { }

    sub bar : ExportGen {
      sub { }
    }

    package My::Dest;
    use My::Lib '*';
  }

  use Data::Dumper;
  say Dumper (My::Lib->EXPORT->info);
  say Dumper ($My::Lib::EVO_EXPORT_META->info);
  say "cache of My::Dest: ", Dumper($My::Dest::EVO_EXPORT_CACHE);

=head4 import

By default, this method will be exported and do the stuff. If you need replace C<import> of your module, exclude it by C<use Evo '-Export * -import'>

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
