use ExtUtils::MakeMaker;
use Config;
use strict;

my @programs_to_install = qw(mp3info2 typeset_audio_dir audio_rename);

my $lib_only = (grep /^LIB=/, @ARGV and not grep /^INSTALLSCRIPT=/, @ARGV);
my @scr = grep /^INSTALLSCRIPT=/, @ARGV;
(my $scr = pop @scr) =~ s/^INSTALLSCRIPT=//;
$scr = $Config{installscript} unless defined $scr;

if ( grep $_ eq '-n', @ARGV or $lib_only ) {
  @ARGV = grep $_ ne '-n', @ARGV;
  warn "I see LIB= but not no INSTALLSCRIPT=\n" if $lib_only;
  warn "Skipping installation of scripts...\n";
  @programs_to_install = ();
} else {
  warn <<EOW;

This program comes with several scripts which I would try to install in
directory $scr.

To skip, rerun with option -n given to Makefile.PL.

EOW
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MP3::Tag',
    'VERSION_FROM'	=> 'lib/MP3/Tag.pm', # finds $VERSION
    'EXE_FILES'		=> [ map "examples/$_", @programs_to_install ],
#    'PMLIBDIRS'         => ['Tag', 'MP3::Tag'],
    'AUTHOR'            => '"Thomas Geffert" <thg@users.sourceforge.net>, "Ilya Zakharevich" ilyaz@cpan.org',
    'PREREQ_PM'         => {
				# Compress::Zlib => 0,
			   },
    'PL_FILES'          => {'data_pod.PL'=>'lib/MP3/Tag/ID3v2_Data.pod'},
 #   'clean'             => {FILES => 'ID3v2_Data.pod'},	# is included!
);

# Tell MakeMaker about manifying ID3v2_Data.pod
package MY;
sub manifypods {
    my $self = shift;
    $self->{MAN3PODS}->{'lib/MP3/Tag/ID3v2_Data.pod'} = '$(INST_MAN3DIR)/MP3::Tag::ID3v2_Data.$(MAN3EXT)';
    $self->SUPER::manifypods(@_);
}

sub postamble {	# Not good enough: is done after .pod is moved to INST_LIB...
  '
lib/MP3/Tag/ID3v2_Data.pod :: lib/MP3/Tag/ID3v2.pm # pm_to_blib

';
}
