require 5.006;
package Mail::Box::MH::Resource;
use Cwd;
use File::Spec;
use Mail::Reporter;
use vars ('$VERSION', @ISA);
$VERSION = 0.06;
@ISA = 'Mail::Reporter';

local($_, $/, %ENV);

my $curdir = File::Spec->catfile(File::Spec->curdir(), 'foo');
   $curdir =~s/\bfoo$//;

sub new{
  shift;
  my $self = bless {};
  $self->SUPER::init();

  unless( $self->{_file} = shift ){
    if( exists($ENV{MH}) ){
      $self->{_file} = File::Spec->file_name_is_absolute($ENV{MH}) ?
	$ENV{MH} : File::Spec->catfile(cwd(), $ENV{MH});
    }
    $self->{_file} ||= File::Spec->catfile($ENV{HOME}, '.mh_profile');
  }
  unless( File::Spec->file_name_is_absolute($self->{_file}) ||
	  $self->{_file} =~ m%^\Q$curdir\E% ){
    my $profile = Mail::Box::MH::Resource->new();
    my $path = $profile->get('Path');
    $path = File::Spec->file_name_is_absolute($path) ? $path :
      File::Spec->catdir($ENV{HOME}, $path);
    $self->{_file} = File::Spec->catfile($path, $self->{_file});
  }

  if( -e $self->{_file} ){
    if( open(my $profile, $self->{_file}) ){
      while( <$profile> ){
	chomp;
	next unless defined($_);
	#MH doesn't strip out leading whitespace, so this is okay
	my @F = split(/:\s*/, $_ ,2);
	$self->{_profile}->{$F[0]} = $F[1];
      }
      close($profile);
      $self->log(PROGRESS=>"Resource file F<$self->{_file}> opened for read.");
    }
    else{
      $self->log(ERROR=>"Resource file F<$self->{_file}> could not be opened for read: $!");
      return;
    }
  }
  else{
    $self->log(NOTICE=>"Resource file F<$self->{_file}> does not exist, it will be created on close()");
  }
  return $self;
}

sub get{
  return @{shift->{_profile}}{@_};
}

sub set{
  my $self = shift;
  my %hash = @_;
  $self->{_profile}->{$_} = $hash{$_} for keys %hash;
  #XXX Should this actually only get touched if any keys are *modified*?
  $self->{_modified} = 1;
};

sub close{
  my $self = shift;
  if( open(my $profile, '>', $self->{_file}) ){
    print $profile "$_: $self->{_profile}->{$_}$/" for keys %{$self->{_profile}};
    close($profile) && ($self->{_modified} = 0);
    $self->log(PROGRESS=>"Resource file F<$self->{_file}> synced.");
  }
  else{
    $self->log(ERROR=>"Resource file F<$self->{_file}> could not be open for write: $!");
   }
};

sub enum{
  keys %{shift->{_profile}};
}

sub DESTROY{
  my $self = shift;
  return unless $self->{_modified};
  require Data::Dumper;
  $self->log(
	     WARNING=>"Resource file F<$self->{_file}> modifications
were destroyed, save changes by calling close() first:\n".
	     Data::Dumper->Dump([$self->{_profile}]));
}

1;
__END__
=pod

=head1 NAME

Mail::Box::MH::Resource - Manage an MH resource file such as the MH profile

=head1 SYNOPSIS

  #Create object and load profile
  my $prof = Mail::Box::MH::Resource->new();

  #Get a list of the profile components
  my @keys = $prof->enum();

  #Get MH directory to pass to Mail::Box::Manager
  my $folderdir = $prof->get('Path');
  $folderdir = File::Spec->file_name_is_absolute($folderdir->{Path}) ?
                                                 $folderdir->{Path}  :
                 File::Spec->catfile($ENV{HOME}, $folderdir->{Path})

  #Permanently remove messages
  $prof->set('rmmproc'=>'rm');

  #Save changes
  $prof->close();

=head1 DESCRIPTION

Read and write MH format resource files such as profile, context, and sequence.

=head1 METHODS

=over

=item new [FILENAME]

Open a resource file, accepts an optional filename of the resource file to
open. I<Non-absolute filenames which do not start with your system's
designation for the current directory are opened relative to the MH profile
Path component>. C<./> should work on most right minded systems, C<:> for
Macintosh, see File::Spec if you don't what it is for your system. If
unspecified new falls back to $ENV{MH} and then $HOME/.mh_profile.

Example:

  #Create a new profile
  my $prof = Mail::Box::MH::Resource->new('/tmp/.mh_profile');

  #Load the context file to determine the currently selected folder
  my $cntx = Mail::Box::MH::Resource->new('current');

=item enum

Returns a list of existing component names.

=item get COMPONENT [COMPONENTS]

Return the values of one or more components.
See L</SYNOPSIS> for an example.

=item set COMPONENT [COMPONENTS]

Set the values of one or more components.
See L</SYNOPSIS> for an example.

=item close

Write the resource file to disk, original component ordering is I<not>
preserved.

=back

=head1 CAVEATS

Order is not preserved therefore "comments" may end up misplaced.

=head1 SEE ALSO

L<mh-profile(5)>, L<Mail::Box::MH>.

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

=cut
