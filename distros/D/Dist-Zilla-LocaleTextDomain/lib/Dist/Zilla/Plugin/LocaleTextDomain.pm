# ABSTRACT: Compile Local::TextDomain language files

package Dist::Zilla::Plugin::LocaleTextDomain;
use strict;
use warnings;
use Moose;
use Path::Class;
use IPC::Cmd qw(can_run);
use IPC::Run3;
use MooseX::Types::Path::Class;
use Moose::Util::TypeConstraints;
use Dist::Zilla::File::FromCode;
use File::Path 2.07 qw(make_path remove_tree);
use namespace::autoclean;

with 'Dist::Zilla::Role::FileGatherer';

with 'Dist::Zilla::Role::FileFinderUser' => {
    default_finders  => [ ':InstallModules', ':ExecFiles' ],
};

our $VERSION = '0.90';

use IPC::Cmd qw(can_run);
BEGIN {
    subtype 'App', as 'Str', where { !!can_run $_ },  message {
        qq{Cannot find "$_": Are the GNU gettext utilities installed?};
    };
}

has textdomain => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->zilla->name },
);

has lang_dir => (
    is      => 'ro',
    isa     => 'Path::Class::Dir',
    coerce  => 1,
    default => sub { dir 'po' },
);

has share_dir => (
    is      => 'ro',
    isa     => 'Path::Class::Dir',
    coerce  => 1,
    default => sub { dir 'share' },
);

has _tmp_dir => (
    is      => 'ro',
    isa     => 'Path::Class::Dir',
    default => sub {
        require File::Temp;
        dir File::Temp::tempdir(CLEANUP => 1);
    },
);

has msgfmt => (
    is      => 'ro',
    isa     => 'App',
    default => sub { 'msgfmt' }
);

has lang_file_suffix => (
    is      => 'ro',
    isa     => 'Str',
    default => 'po',
);

has bin_file_suffix => (
    is      => 'ro',
    isa     => 'Str',
    default => 'mo',
);

has language => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $lang_dir = $self->lang_dir;
        my $lang_ext = $self->lang_file_suffix;
        my @langs;
        for my $file ( $lang_dir->children ) {
            next if $file->is_dir || $file !~ /[.]$lang_ext\z/;
            (my $lang = $file->basename) =~ s/[.]$lang_ext\z//;
            push @langs => $lang;
        }
        return \@langs;
    },
);

sub mvp_multivalue_args { return qw(language) }

sub gather_files {
    my ($self, $arg) = @_;

    my $dzil     = $self->zilla;
    my $lang_dir = $self->lang_dir;
    my $lang_ext = $self->lang_file_suffix;
    my $bin_ext  = $self->bin_file_suffix;
    my $txt_dom  = $self->textdomain;
    my $shr_dir  = $self->share_dir;
    my $tmp_dir  = $self->_tmp_dir;

    my @cmd = (
        $self->msgfmt,
        '--check',
        '--statistics',
        '--verbose',
        '--output-file',
    );

    unless (-d $lang_dir) {
        $self->log(
            "Skipping language compilation: directory $lang_dir does not exist"
        );
        return;
    }

    $self->log("Compiling language files in $lang_dir");
    make_path $tmp_dir->stringify;
    my @encoding_params = Dist::Zilla::File::FromCode->VERSION >= 5.0 ? (
        encoding         => 'bytes',
        code_return_type => 'bytes',
    ) : ();

    for my $lang (@{ $self->language }) {
        my $file = $lang_dir->file("$lang.$lang_ext");
        my $dest = file $shr_dir, 'LocaleData', $lang, 'LC_MESSAGES',
            "$txt_dom.$bin_ext";
        my $temp = $tmp_dir->file("$lang.$bin_ext");
        my $log = sub { $self->log(@_) };
        $self->add_file(
            Dist::Zilla::File::FromCode->new({
                @encoding_params,
                name => $dest->stringify,
                code => sub {
                    run3 [@cmd, $temp, $file], undef, $log, $log;
                    $dzil->log_fatal("Cannot compile $file") if $?;
                    scalar $temp->slurp(iomode => '<:raw');
                },
            })
        );
    }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 Name

Dist::Zilla::Plugin::LocaleTextDomain - Compile Local::TextDomain language files

=head1 Synopsis

In F<dist.ini>:

  [ShareDir]
  [LocaleTextDomain]
  textdomain = My-App
  lang_dir = po
  share_dir = share

=head1 Description

This plugin compiles GNU gettext language files and adds them into the
distribution for use by L<Locale::TextDomain>. This is useful if your
distribution maintains gettext language files in a directory, with each file
named for a language. The plugin uses C<msgfmt> to compile each file and then
adds it to the distribution's F<share> directory. You can then use the
L<ShareDir plugin|Dist::Zilla::Plugin::ShareDir> to make sure it gets
installed in the right place.

=head2 Installation

By default, L<Locale::TextDomain> searches for language files in the shared
directory for your distribution, as defined by L<File::ShareDir>. Prior to
v1.21, however, this was not the case. Instead, it searched for files in
Perl's C<@INC> directories. If you're stuck with one of these older versions
of Locale::TextDomain, you'll have to install the compiled language files into
the F<lib> directory in your distribution. To do so, simply set the
C<share_dir> attribute to "lib":

  [LocaleTextDomain]
  textdomain = My-App
  lang_dir = po
  share_dir = lib

If your distribution uses L<ExtUtils::MakeMaker> to do the installation, the
files will now be installed in the proper location. If it relies on
L<Module::Build>, you will have to do a bit of additional work. First, subclass
Module::Build by creating F<inc/Module/Build/MyApp.pm> with this code:

  package Module::Build::MyApp;
  use parent 'Module::Build';

  sub new {
      my ( $class, %p ) = @_;
      my $self = $class->SUPER::new(%p);
      $self->add_build_element('mo');
      return $self;
  }

Then tell L<Dist::Zilla> to use the subclass via the C<mb_class> attribute in
F<dist.ini>:

  [ModuleBuild]
  mb_class = Module::Build::MyApp

Now the F<.mo> files will be installed where L<Locale::TextDomain> can find
them.

=head2 Configuration

Configuration attributes settable in F<dist.ini> to change the plugin
behavior.

=head3 C<textdomain>

The textdomain to use for your language files, as defined by the
L<Locale::TextDomain> documentation. This should be the same value declared
in each use of Locale::TextDomain in your module. For example, if such lines
look like this:

  use LocaleText::Domain qw(com.example.myApp);

Then set it to such in your F<dist.ini>

  [LocaleTextDomain]
  textdomain = com.example.myApp

Defaults to the name of your distribution, which is the value that
L<Locale::TextDomain> recommends you use.

=head3 C<lang_dir>

The directory containing your language files. Defaults to F<po>.

=head3 C<share_dir>

The name of the distribution directory into which compiled language files
should be added. Defaults to C<share>.

=head3 C<msgfmt>

The location of the C<msgfmt> program, which is distributed with L<GNU
gettext|http://www.gnu.org/software/gettext/>. Defaults to just C<msgfmt>,
which should work if it's in your path.

=head3 C<language>

A language to be compiled. May be specified more than once. If not specified,
the default will be the list of files in C<lang_dir> ending in
C<lange_file_suffix>.

=head3 C<lang_file_suffix>

Suffix used in the language file names. These are the files your translators
maintain in your repository. Defaults to C<po>.

=head3 C<bin_file_suffix>

Suffix to use for the compiled language file. Defaults to C<mo>.

=head3 C<finder>

File finders to use to look for files to search for strings to extract. May be
specified more than once. If not specified, the default will be
C<:InstallModules> and C<:ExecFiles>; that is, files below F<lib/> and
executable files marked by e.g. the L<C<ExecDir>|Dist::Zilla::Plugin::ExecDir>
plugin. You can also combine default finders with custom ones based on a
L<C<FileFinder>|Dist::Zilla::Role::FileFinder> plugin. For example:

  [FileFinder::ByName / MyFiles]
  file = *.pl

  [LocaleTextDomain]
  finder = MyFiles
  finder = :ShareFiles

This configuration will extract strings from files that match C<*.pl> and all
files in a share directory.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012-2013 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
