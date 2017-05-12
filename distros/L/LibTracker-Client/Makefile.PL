use 5.008008;
use ExtUtils::MakeMaker;

# experimental - check for dependencies.
# tip from http://cpantest.grango.org/wiki/CPANAuthorNotes
# via 'imacat <imacat@mail.imacat.idv.tw>'
use lib 'inc';
use Devel::CheckLib;
check_lib_or_exit( lib => [ 'trackerclient', 'glib-2.0', 'dbus-glib-1' ],
		headers => [ 'tracker-client.h', 'tracker.h' ] );

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'LibTracker::Client',
    VERSION_FROM      => 'lib/LibTracker/Client.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/LibTracker/Client.pm', # retrieve abstract from module
       AUTHOR         => 'Devendra Gera <gera@theoldmonk.net>') : ()),
    LIBS              => ['-ltrackerclient'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. `pkg-config --cflags dbus-glib-1 glib-2.0`', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(DATA_DATE DATA_NUMERIC DATA_STRING DATA_STRING_INDEXABLE
		 SERVICE_APPLICATIONS SERVICE_APPOINTMENTS SERVICE_BOOKMARKS
		 SERVICE_CONTACTS SERVICE_CONVERSATIONS
		 SERVICE_DEVELOPMENT_FILES SERVICE_DOCUMENTS
		 SERVICE_EMAILATTACHMENTS SERVICE_EMAILS SERVICE_FILES
		 SERVICE_FOLDERS SERVICE_HISTORY SERVICE_IMAGES SERVICE_MUSIC
		 SERVICE_OTHER_FILES SERVICE_PLAYLISTS SERVICE_PROJECTS
		 SERVICE_TASKS SERVICE_TEXT_FILES SERVICE_VFS_DEVELOPMENT_FILES
		 SERVICE_VFS_DOCUMENTS SERVICE_VFS_FILES SERVICE_VFS_FOLDERS
		 SERVICE_VFS_IMAGES SERVICE_VFS_MUSIC SERVICE_VFS_OTHER_FILES
		 SERVICE_VFS_TEXT_FILES SERVICE_VFS_VIDEOS SERVICE_VIDEOS));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'LibTracker::Client',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
