package Dist::Zilla::Plugin::Author::Plicease::Core 2.37 {

  use 5.014;
  use Moose;
  use Module::CoreList ();
  use version ();
  
  # ABSTRACT: Handle core prereqs
  # VERSION
  
  with 'Dist::Zilla::Role::PrereqSource', 'Dist::Zilla::Role::InstallTool';
  
  has starting_version => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      my $version = $self->zilla->prereqs->as_string_hash->{runtime}->{requires}->{perl};
      $self->log("guessing perl version $version");
      $version;
    },
  );

  has check_at_configure => (
    is      => 'ro',
    default => sub { { } },
  );

  sub register_prereqs
  {
    my($self) = @_;
    
    my $prereqs = $self->zilla->prereqs->as_string_hash;
    
    foreach my $phase (keys %$prereqs)
    {
      foreach my $type (keys %{ $prereqs->{$phase} })
      {
        foreach my $module (sort keys %{ $prereqs->{$phase}->{$type} })
        {
          next if $module =~ /^(ExtUtils::MakeMaker|Module::Build)$/;
          my $value = $prereqs->{$phase}->{$type}->{$module};
          next unless $value == 0;
          my $added_in = Module::CoreList->first_release($module);
          next unless defined $added_in;
          #$self->log("considering $phase $type $module");
          #$self->log("addedin = $added_in");
          #$self->log("starting_version = @{[ version->parse($self->starting_version) ]}");
          #$self->log("added_in         = @{[ version->parse($added_in) ]}");
          if(version->parse($self->starting_version) >= version->parse($added_in))
          {
            $self->log("removing prereq: $module");
            $self->zilla->prereqs->requirements_for($phase, $type)->clear_requirement($module);
            $self->check_at_configure->{$module}++;
          }
        }
      }
    }
  }
  
  sub setup_installer
  {
    my($self) = @_;
    foreach my $file (grep { $_->name =~ /^(Makefile\.PL|Build\.PL)$/ } @{ $self->zilla->files })
    {
      my $content = $file->content;
      
      $content = join "\n",
        "BEGIN {",
        "  use strict; use warnings;",
        "  my \%missing = map {",
        "    eval qq{ require \$_ };",
        "    \$\@ ? (\$_=>1) : ()",
        "  } qw( @{[ sort keys %{ $self->check_at_configure } ]} );",
        "  if(%missing)",
        "  {",
        "    print \"Your Perl is missing core modules: \@{[ sort keys \%missing ]}\\n\";",
        (map { "    print \"$_\\n\";" }
          "Ideally if you are using the system Perl you can install the appropriate",
          "package which includes the core Perl modules.  On at least some versions",
          "of Fedora, CentOS and RHEL, this is the `perl-core` package.",
          "",
          " \% dnf install perl-core",
          "   ~ or ~",
          " \% yum install perl-core",
          "",
          "If you really want to install dual-life modules from CPAN, then you can",
          "use cpanm:",
          "",
          " \% cpanm \@{[ sort keys \%missing ]}",
          "",
          "Note that some core modules are not available from CPAN.",
        ),
        "    exit;",
        "  }",
        "}",
        $content;
      
      $file->content($content);
    }
    
  }
  

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::Plicease::Core - Handle core prereqs

=head1 VERSION

version 2.37

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
