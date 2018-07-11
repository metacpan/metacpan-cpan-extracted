#line 1
package Module::Install::GetProgramLocations;

use strict;
use 5.005;

use Config;
use Cwd;
use Carp;
use File::Spec;
use Sort::Versions;
use Exporter();

use vars qw( @ISA $VERSION @EXPORT );

use Module::Install::Base;
@ISA = qw( Module::Install::Base Exporter );

@EXPORT = qw( &get_gnu_version
              &get_bzip2_version
            );

$VERSION = sprintf "%d.%02d%02d", q/0.30.10/ =~ /(\d+)/g;

# ---------------------------------------------------------------------------

sub get_program_locations
{
  my $self = shift;
  my %info = %{ shift @_ };

  foreach my $program (keys %info)
  {
    croak "argname is required for $program"
      unless defined $info{$program}{'argname'};

    if (exists $info{$program}{'types'}) {
      foreach my $type (keys %{ $info{$program}{'types'} }) {
        next unless exists $info{$program}{'types'}{$type}{'fetch'};

        croak "Fetch routine must be a valid code reference"
          unless ref $info{$program}{'types'}{$type}{'fetch'} eq "CODE" &&
            defined &{ $info{$program}{'types'}{$type}{'fetch'} };
      }
    }
  }

  $self->include_deps('Config',0);
  $self->include_deps('File::Spec',0);
  $self->include_deps('Sort::Versions',0);
  $self->include_deps('Cwd',0);

  my %user_specified_program_paths =
    $self->_get_user_specified_program_locations(\%info);

  if (keys %user_specified_program_paths)
  {
    return $self->_get_argv_program_locations(\%info,
      \%user_specified_program_paths);
  }
  else
  {
    return $self->_prompt_user_for_program_locations(\%info);
  }
}

# ---------------------------------------------------------------------------

sub _get_user_specified_program_locations
{
  my $self = shift;
  my %info = %{ shift @_ };

  my %user_specified_program_paths;
  my @remaining_args;

  # Look for user-provided paths in @ARGV
  foreach my $arg (@ARGV)
  {
    my ($var,$value) = $arg =~ /^(.*?)=(.*)$/;

    push(@remaining_args, $arg), next unless defined $var;

    $value = undef if $value eq '';

    my $is_a_program_arg = 0;

    foreach my $program (keys %info)
    {
      if ($var eq $info{$program}{'argname'})
      {
        $user_specified_program_paths{$program} = $value;
        $is_a_program_arg = 1;
        last;
      }
    }

    push @remaining_args, $arg unless $is_a_program_arg;
  }

  @ARGV = @remaining_args;

  return %user_specified_program_paths;
}

# ---------------------------------------------------------------------------

sub _get_argv_program_locations
{
  my $self = shift;
  my %info = %{ shift @_ };
  my %program_locations = %{ shift @_ };

  my %program_info;

  foreach my $program_name (sort keys %info)
  {
    $program_info{$program_name} = 
      { 'path' => undef, 'type' => undef, 'version' => undef };

    next if exists $program_locations{$program_name} &&
      $program_locations{$program_name} eq '';

    $program_locations{$program_name} = $info{$program_name}{'default'}
      unless exists $program_locations{$program_name};

    my $full_path = $self->_Make_Absolute($program_locations{$program_name});
    if (!defined $self->can_run($full_path))
    {
      warn "\"$full_path\" does not appear to be a valid executable\n";
      warn "Using anyway\n";

      $program_info{$program_name} =
        { path => $full_path, type => undef, version => undef };
    }
    else
    {
      my ($is_valid,$type,$version) = 
        $self->_program_version_is_valid($program_name,$full_path,\%info);
      
      unless($is_valid)
      {
        warn "\"$full_path\" is not a correct version\n";
        warn "Using anyway\n";
      }

      $program_info{$program_name} =
        { path => $full_path, type => $type, version => $version };
    }
  }

  return %program_info;
}

# ---------------------------------------------------------------------------

sub _prompt_user_for_program_locations
{
  my $self = shift;
  my %info = %{ shift @_ };

  # Force the include inc/Module/Install/Can.pm message to appear early
  $self->can_run();

  print "Enter the full path, or \"none\" for none.\n";

  my $last_choice = '';

  my %program_info;

  ASK: foreach my $program_name (sort keys %info)
  {
    my ($name,$full_path);

    # Convert any default to a full path, initially
    $name = $Config{$program_name};
    $full_path = $self->can_run($name);

    if ($name eq '' || !defined $full_path)
    {
      $name = $info{$program_name}{'default'};
      $full_path = $self->can_run($name);
    }

    $full_path = 'none' if !defined $full_path || $name eq '';

    my $allowed_types = '';
    if (exists $info{$program_name}{'types'})
    {
      foreach my $type (keys %{ $info{$program_name}{'types'} } )
      {
        $allowed_types .= ", $type";
      }

      $allowed_types =~ s/^, //;
      $allowed_types =~ s/(.*), /$1, or /;
      $allowed_types = " ($allowed_types";
      $allowed_types .= scalar(keys %{ $info{$program_name}{'types'} }) > 1 ?
        " types)" : " type)";
    }

    my $choice = $self->prompt(
      "Where can I find your \"$program_name\" executable?" .
      "$allowed_types", $full_path);

    $program_info{$program_name} =
      { path => undef, type => undef, version => undef }, next
      if $choice eq 'none';

    $choice = $self->_Make_Absolute($choice);

    if (!defined $self->can_run($choice))
    {
      warn "\"$choice\" does not appear to be a valid executable\n";

      if ($last_choice ne $choice)
      {
        $last_choice = $choice;
        redo ASK;
      }

      warn "Using anyway\n";
    }
    else
    {
      my ($is_valid,$type,$version) = 
        $self->_program_version_is_valid($program_name,$choice,\%info);
      
      if(!$is_valid)
      {
        warn "\"$choice\" is not a correct version\n";

        if ($last_choice ne $choice)
        {
          $last_choice = $choice;
          redo ASK;
        }

        warn "Using anyway\n";
      }

      $program_info{$program_name} =
        { path => $choice, type => $type, version => $version };
    }
  }

  return %program_info;
}

# ---------------------------------------------------------------------------

sub _program_version_is_valid
{
  my $self = shift;
  my $program_name = shift;
  my $program = shift;
  my %info = %{ shift @_ };

  if (exists $info{$program_name}{'types'})
  {
    my $version;

    TYPE: foreach my $type (keys %{$info{$program_name}{'types'}})
    {
      $version = &{$info{$program_name}{'types'}{$type}{'fetch'}}($program);

      next TYPE unless defined $version;

      if ($self->version_matches_range($version,
        $info{$program_name}{'types'}{$type}{'numbers'}))
      {
        return (1,$type,$version);
      }
    }

    my $version_string = '<UNKNOWN>';
    $version_string = $version if defined $version;
    warn "\"$program\" version $version_string is not valid for any of the following:\n";

    foreach my $type (keys %{$info{$program_name}{'types'}})
    {
      warn "  $type => " .
        $info{$program_name}{'types'}{$type}{'numbers'} . "\n";
    }

    return (0,undef,undef);
  }

  return (1,undef,undef);
}

# ---------------------------------------------------------------------------

sub version_matches_range
{
  my $self = shift;
  my $version = shift;
  my $version_specification = shift;

  my $range_pattern = '([\[\(].*?\s*,\s*.*?[\]\)])';

  my @ranges = $version_specification =~ /$range_pattern/g;

  die "Version specification \"$version_specification\" is incorrect\n"
    unless @ranges;

  foreach my $range (@ranges)
  {
    my ($lower_bound,$lower_version,$upper_version,$upper_bound) =
      ( $range =~ /([\[\(])(.*?)\s*,\s*(.*?)([\]\)])/ );
    $lower_bound = '>' . ( $lower_bound eq '[' ? '=' : '');
    $upper_bound = '<' . ( $upper_bound eq ']' ? '=' : '');

    my ($lower_bound_satisified, $upper_bound_satisified);

    $lower_bound_satisified =
      ($lower_version eq '' || versioncmp($version,$lower_version) == 1 ||
      ($lower_bound eq '>=' && versioncmp($version,$lower_version) == 0));
    $upper_bound_satisified =
      ($upper_version eq '' || versioncmp($version,$upper_version) == -1 ||
      ($upper_bound eq '<=' && versioncmp($version,$upper_version) == 0));

    return 1 if $lower_bound_satisified && $upper_bound_satisified;
  }

  return 0;
}

# ---------------------------------------------------------------------------

# Returns the original if the full path can't be found
sub _Make_Absolute
{
  my $self = shift;
  my $program = shift;

  if(File::Spec->file_name_is_absolute($program))
  {
    return $program;
  }
  else
  {
    my $path_to_choice = undef;

    foreach my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), cwd())
    {
      $path_to_choice = File::Spec->catfile($dir, $program);
      last if defined $self->can_run($path_to_choice);
    }

    return $program unless -e $path_to_choice;

    warn "WARNING: Avoiding security risks by converting to absolute paths\n";
    warn "\"$program\" is currently in your path at \"$path_to_choice\"\n";

    return $path_to_choice;
  }
}

# ---------------------------------------------------------------------------

sub get_gnu_version
{
  my $program = shift;

  die "Missing GNU program to get version for" unless defined $program;

  my $version_message;

  # Newer versions
  {
    my $command = "\"$program\" --version 2>" . File::Spec->devnull();
    $version_message = `$command`;
  }

  # Older versions use -V
  unless($version_message =~ /\b(GNU|Free\s+Software\s+Foundation)\b/s)
  {
    my $command = "\"$program\" -V 2>&1 1>" . File::Spec->devnull();
    $version_message = `$command`;
  }

  return undef unless ## no critic (ProhibitExplicitReturnUndef)
    $version_message =~ /\b(GNU|Free\s+Software\s+Foundation)\b/s;

  my ($program_version) = $version_message =~ /^.*?([\d]+\.[\d.a-z]+)/s;

  return $program_version;
}

# ---------------------------------------------------------------------------

sub get_bzip2_version
{
  my $program = shift;

  my $command = "\"$program\" --help 2>&1 1>" . File::Spec->devnull();
  my $version_message = `$command`;

  my ($program_version) = $version_message =~ /^.*?([\d]+\.[\d.a-z]+)/s;

  return $program_version;
}

1;

# ---------------------------------------------------------------------------

#line 629
