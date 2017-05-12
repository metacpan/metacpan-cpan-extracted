package Module::Install::PRIVATE::Configure_Programs;

use strict;
use warnings;
use File::Slurp;

use lib 'inc';
use Module::Install::GetProgramLocations;

use vars qw( @ISA $VERSION );

use Module::Install::Base;
@ISA = qw( Module::Install::Base );

$VERSION = sprintf "%d.%02d%02d", q/0.1.0/ =~ /(\d+)/g;

# ---------------------------------------------------------------------------

sub configure_programs {
  my ($self, @args) = @_;

  $self->include('Module::Install::GetProgramLocations', 0);
  $self->configure_requires('File::Slurp', 0);

  my %info = (
      'cat'      => { default => 'cat', argname => 'CAT' },
      'diff'     => { default => 'diff', argname => 'DIFF' },
      'grep'     => { default => 'grep', argname => 'GREP',
                      types => {
                        'GNU' => { fetch => \&get_gnu_version,
                                   numbers => '[2.1,)', },
                      },
                    },
      'lzip'     => { default => 'lzip', argname => 'LZIP',
                      types => {
                        'GNU' => { fetch => \&get_gnu_version,
                                   numbers => '[1.3,)', },
                      },
                    },
      'xz'       => { default => 'xz', argname => 'XZ' },
      'gzip'     => { default => 'gzip', argname => 'GZIP' },
      'bzip'     => { default => 'bzip2', argname => 'BZIP',
                      types => {
                        'bzip2' => { fetch => \&get_bzip2_version,
                                     numbers => '[1.0,)', },
                      },
                    },
      'bzip2'    => { default => 'bzip2', argname => 'BZIP2',
                      types => {
                        'bzip2' => { fetch => \&get_bzip2_version,
                                     numbers => '[1.0,)', },
                      },
                    },
  );

	# XXX: disable grep support by pretending like the user doesn't have grep
	# installed
	delete $info{'grep'};

  my %locations = $self->get_program_locations(\%info);

  # XXX: pretend we didn't find grep
  $locations{'grep'} = {
		'version' => undef, 'type' => undef, 'path' => undef
	};

  Update_Config('lib/Mail/Mbox/MessageParser/Config.pm', \%locations);
  Update_Config('old/Mail/Mbox/MessageParser/Config.pm', \%locations)
    if -e 'old/Mail/Mbox/MessageParser.pm';

  return \%locations;
}

# --------------------------------------------------------------------------

sub Update_Config
{
  my $filename = shift;
  my %locations = %{ shift @_ };

  my $code = read_file($filename);

  foreach my $program (keys %locations)
  {
    if (defined $locations{$program}{'path'})
    {
      $locations{$program}{'path'} = "\'$locations{$program}{'path'}\'";
    }
    else
    {
      $locations{$program}{'path'} = "undef";
    }
  }

  if ($code =~ /'programs'\s*=>\s*{\s*?\n([^}]+?) *}/s)
  {
    my $original_programs = $1;
    my $new_programs = '';

    foreach my $program (sort keys %locations)
    {
      $new_programs .= "    '$program' => $locations{$program}{'path'},\n";
    }

    $code =~ s/\Q$original_programs\E/$new_programs/;
  }
  else
  {
    die "Couldn't find programs hash in $filename";
  }

  write_file($filename, $code);
}
