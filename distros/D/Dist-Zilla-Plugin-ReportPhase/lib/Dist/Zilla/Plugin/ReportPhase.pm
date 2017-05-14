package Dist::Zilla::Plugin::ReportPhase;
# ABSTRACT: Log every role use in every phase executed.
BEGIN
  {
    $Dist::Zilla::Plugin::ReportPhase::VERSION
      = substr '$$Version: 0.03 $$', 11, -3;
  }

use 5.006;
use Moose;
use Moose::Autobox;
use Data::Dumper;

with
  ( 'Dist::Zilla::Role::AfterBuild'
  , 'Dist::Zilla::Role::AfterMint'
  , 'Dist::Zilla::Role::AfterRelease'
  , 'Dist::Zilla::Role::BeforeArchive'
  , 'Dist::Zilla::Role::BeforeBuild'
  , 'Dist::Zilla::Role::BeforeMint'
  , 'Dist::Zilla::Role::BeforeRelease'
  , 'Dist::Zilla::Role::BuildRunner'
  , 'Dist::Zilla::Role::ConfigDumper'
  , 'Dist::Zilla::Role::FileFinder'
  , 'Dist::Zilla::Role::FileGatherer'
  , 'Dist::Zilla::Role::FileMunger'
  , 'Dist::Zilla::Role::FilePruner'
  , 'Dist::Zilla::Role::InstallTool'
  , 'Dist::Zilla::Role::MetaProvider'
  , 'Dist::Zilla::Role::MintingProfile'
  , 'Dist::Zilla::Role::ModuleMaker'
  , 'Dist::Zilla::Role::PrereqSource'
  , 'Dist::Zilla::Role::Releaser'
  , 'Dist::Zilla::Role::ShareDir'
  , 'Dist::Zilla::Role::TestRunner'
  , 'Dist::Zilla::Role::VersionProvider'
  );


my $cmd = ref $App::Cmd::active_cmd;

sub _report{ $_[0]->logger->log("########## $_[1] ##########"); }

sub after_build      { $_[0]->_report("After Build");       }
sub after_mint       { $_[0]->_report("After Mint");	    }
sub after_release    { $_[0]->_report("After Release");     }
sub before_archive   { $_[0]->_report("Before Archive");    }
sub before_build     { $_[0]->_report("Before Build");      }
sub before_mint      { $_[0]->_report("Before Mint");       }
sub before_release   { $_[0]->_report("Before Release");    }
sub build	     { $_[0]->_report("Build");		    }
sub bundle_config    { $_[0]->_report("Bundle Config");	    }
sub dump_config      { $_[0]->_report("Dump Config");       }
sub find_files       { $_[0]->_report("Find Files");	    }
sub gather_files     { $_[0]->_report("Gather Files");      }
sub make_module      { $_[0]->_report("Module Maker");	    }
sub metadata	     { $_[0]->_report("Metadata");	    }
sub munge_files      { $_[0]->_report("Munge Files");       }
sub munge_file       { $_[0]->_report("Munge File: @{[$_[1]->name]}"); }
sub profile_dir      { $_[0]->_report("Profile Dir");	    }
sub provide_version  { $_[0]->_report("Provide Version");   }
sub prune_files      { $_[0]->_report("Prune Files");       }
sub register_prereqs { $_[0]->_report("Bundle Config");	    }
sub release	     { $_[0]->_report("Release");	    }
sub setup_installer  { $_[0]->_report("Setup Installer");   }
sub share_dir_map    { $_[0]->_report("Share Dir");	    }
sub test	     { $_[0]->_report("Test Runner");       }
sub configure	     { $_[0]->_report("Configure");	    }
sub dir		     { $_[0]->_report("Dir");		    }

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::ReportPhase - Report whats going on.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

In your F<dist.ini>:

  [ReportPhase / Phase_Begins]

  ...

  [ReportPhase / Phase_Ends]

=head1 DESCRIPTION

This plugin was written to give the author some idea of the order that
various roles are invoked under different conditions. So,
B<ReportPhase> implements every major role, and reports when it is
being invoked. For best results it should be used as both the very
first, and the very last plugin listed in dist.ini, as it will then
report entering and exiting every phase.

Other than this phase reporting, this plugin has no use.

=head1 ATTRIBUTES

NONE

=head1 AUTHOR

Stirling Westrup <swestrup@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Stirling Westrup.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
