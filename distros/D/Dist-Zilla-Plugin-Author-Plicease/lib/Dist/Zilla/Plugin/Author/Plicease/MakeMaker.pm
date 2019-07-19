package Dist::Zilla::Plugin::Author::Plicease::MakeMaker 2.37 {

  use 5.014;
  use Moose;
  use namespace::autoclean;
  use Perl::Tidy ();
  use Dist::Zilla::Plugin::Author::Plicease ();
  use List::Util qw( first );

  # ABSTRACT: munge the AUTHOR section


  extends 'Dist::Zilla::Plugin::MakeMaker';

  with 'Dist::Zilla::Role::MetaProvider';

  around write_makefile_args => sub {
    my($orig, $self, @args) = @_;
    my $h = $self->$orig(@args);  

    # to prevent any non .pm/.pod files from being installed in lib
    # because shit like this is stuff we ought to have to customize.
    my %PM = map {; "lib/$_" => "\$(INST_LIB)/$_" } map { s/^lib\///; $_ } grep /^lib\/.*\.p(od|m)$/, map { $_->name } @{ $self->zilla->files };
    $h->{PM} = \%PM;

    $h;
  };

  around setup_installer => sub {
    my($orig, $self, @args) = @_;
    
    $self->$orig(@args);
    
    my $file   = first { $_->name eq 'Makefile.PL' }        @{ $self->zilla->files };
    my $mod    = first { $_->name eq 'inc/mymm.pl' }        @{ $self->zilla->files };
    my $config = first { $_->name eq 'inc/mymm-config.pl' } @{ $self->zilla->files };
    my $build  = first { $_->name eq 'inc/mymm-build.pl' }  @{ $self->zilla->files };
    my $test   = first { $_->name eq 'inc/mymm-test.pl' }   @{ $self->zilla->files };
    my $clean  = first { $_->name eq 'inc/mymm-clean.pl' }  @{ $self->zilla->files };

    my @content = do {
      my $in  = $file->content;
      my $out = '';
      my $err = '';
      local @ARGV = ();
      my $error = Perl::Tidy::perltidy(
        source      => \$in,
        destination => \$out,
        stderr      => \$err,
        perltidyrc  => Dist::Zilla::Plugin::Author::Plicease->dist_dir->child('perltidyrc')->stringify,
      );
      $self->log("perltidy: $_") for split /\n/, $err;
      $self->log_fatal("perltidy failed!") if $error;
      split /\n/, $out;
    };

    # pet-peve1: remove blank lines between use
    {
      my $i = 0;
      while($i<$#content)
      {
        if($content[$i] =~ /^(use|#)/)
        { $i++ }
        elsif($content[$i] =~ /^\s*$/)
        { @content = @content[0..($i-1),($i+1)..$#content] }
        else
        {
          my @extra = ('');
        
          if($mod)
          {
            unshift @extra, 'require "./inc/mymm.pl";';
          }
        
          @content = (
            @content[0..($i-1)], 
            @extra, 
            @content[($i)..$#content]
          );
          last;
        }
      }
    }

    # pet-peve2: squeeze multiple blank lines
    {
      my @new;
      my $last_empty = 0;
      foreach my $line (@content)
      {
        if($line =~ /^\s*$/)
        {
          if($last_empty)
          { next }
          else
          {
            $last_empty = 1;
          }
        }
        else
        {
          $last_empty = 0;
        }

        push @new, $line;
      }
      @content = @new;
    }

    if($mod || $test)
    {
      my $last = pop @content;
      if($last =~ /^WriteMakefile\(/)
      {
        my @new;
        while(defined $content[0] && $content[0] !~ /\%FallbackPrereqs/)
        {
          my $line = shift @content;

          if($test)
          {
            # TODO: not exactly sure when the test order was fixed in EUMM.
            #       research and correct.
            $line =~ s/use ExtUtils::MakeMaker;/use ExtUtils::MakeMaker 7.1001;/;
          }
          else
          {
            $line =~ s/use ExtUtils::MakeMaker;/use ExtUtils::MakeMaker 6.64;/;
          }
        
          push @new, $line;
        }

        eval $mod->content;
        $self->log_fatal("unable to eval inc/mymm.pl: $@") if $@;
        
        if(mymm->can('myWriteMakefile'))
        {
          $last = "mymm::my$last";
        }
        
        @content = ( @new, $last );
      }
      else
      {
        $self->log_fatal("unable to find WriteMakefile in Makefile.PL");
      }
    }


    if($config || $build || $test || $clean)
    {
      push @content, "{ package MY;";
      push @content, "  sub postamble {";
      push @content, "    my \$postamble = '';";
      push @content, '';
      if($config)
      {
        push @content, "    \$postamble .=";
        push @content, "      \"config :: _mm/config\\n\" .";
        push @content, "      \"mymm-config _mm/config:\\n\" .";
        push @content, "      \"\\t\\\$(FULLPERL) inc/mymm-config.pl\\n\" .";
        push @content, "      \"\\t\\\$(NOECHO)\\\$(MKPATH) _mm\\n\" .";
        push @content, "      \"\\t\\\$(NOECHO)\\\$(TOUCH) _mm/config\\n\\n\";";
        push @content, '';
      }
      if($build)
      {
        push @content, "    \$postamble .=";
        push @content, "      \"pure_all :: mymm-build\\n\" .";
        push @content, "      \"mymm-build :@{[ $config ? ' _mm/config' : '' ]}\\n\" .";
        push @content, "      \"\\t\\\$(FULLPERL) inc/mymm-build.pl\\n\\n\";";
        push @content, '';
      }
      if($test)
      {
        push @content, "    \$postamble .=";
        push @content, "      \"subdirs-test_dynamic subdirs-test_static subdirs-test :: mymm-test\\n\" .";
        push @content, "      \"mymm-test :\\n\" .";
        push @content, "      \"\\t\\\$(FULLPERL) inc/mymm-test.pl\\n\\n\";";
        push @content, '';
      }
      if($clean)
      {
        push @content, "    \$postamble .=";
        push @content, "      \"clean :: mymm-clean\\n\" .";
        push @content, "      \"mymm-clean :\\n\" .";
        push @content, "      \"\\t\\\$(FULLPERL) inc/mymm-clean.pl\\n\" .";
        push @content, "      \"\\t\\\$(RM_RF) _mm\\n\\n\";";
        push @content, '';
      }
      push @content, "    \$postamble;";
      push @content, "  }";

      push @content, "  sub special_targets {";
      push @content, "    my(\$self, \@therest) = \@_;";
      push @content, "    my \$st = \$self->SUPER::special_targets(\@therest);";
      push @content, "    \$st .= \"\\n.PHONY:";
      $content[-1] .= " mymm-config" if $config;
      $content[-1] .= " mymm-build" if $build;
      $content[-1] .= " mymm-test" if $test;
      $content[-1] .= " mymm-clean" if $clean;
      $content[-1] .= "\\n\";";
      push @content, "    \$st;";
      push @content, "  }";
      push @content, "}";
    }

    $file->content(join "\n", @content);

    return;
  };

  around register_prereqs => sub {
    my($orig, $self, @args) = @_;
    my $h = $self->$orig(@args);  

    my $mod  = first { $_->name eq 'inc/mymm.pl' } @{ $self->zilla->files };
    if($mod)
    {
      $self->zilla->register_prereqs(
        { phase => 'configure' },
        'ExtUtils::MakeMaker' => '6.64'
      );
    }

    my $test = first { $_->name eq 'inc/mymm-test.pl' } @{ $self->zilla->files };
    if($test)
    {
      $self->zilla->register_prereqs(
        { phase => 'configure' },
        'ExtUtils::MakeMaker' => '7.1001'
      );
    }
    
    return;
  };

  sub metadata
  {
    my($self) = @_;
    
    my %meta;
    
    my $mod  = first { $_->name eq 'inc/mymm.pl' } @{ $self->zilla->files };
    
    $meta{dynamic_config} = 1 if $mod;

    \%meta;
  }

  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::MakeMaker - munge the AUTHOR section

=head1 VERSION

version 2.37

=head1 SYNOPSIS

 [Author::Plicease::MakeMaker]

=head1 DESCRIPTION

My personal customization of the L<Dist::Zilla::Plugin::MakeMaker>.  You are unlikely to
need or want to use this.

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::Plicease>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
