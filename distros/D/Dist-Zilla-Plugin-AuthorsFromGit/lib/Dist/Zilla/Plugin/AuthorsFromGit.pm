package Dist::Zilla::Plugin::AuthorsFromGit;
# ABSTRACT: Add per-file per-year copyright info to each Perl document
$Dist::Zilla::Plugin::AuthorsFromGit::VERSION = '0.005';
use Git::Wrapper;
use DateTime;
use List::MoreUtils 0.4 qw(uniq sort_by true);

use Moose;
with(
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules', ':ExecFiles' ],
  },
);

use namespace::autoclean;


sub getblacklist {
  open ( my $lf, '<', '.copyright-exclude' ) or return ( );
  my @lines=<$lf>;
  chomp @lines;
  return @lines;
};


sub gitauthorlist {
  my ($file, $git)= @_;

  my @log_lines = $git->RUN('log', '--follow', '--format=%H %at %aN', '--', $file->name);
  my @outputlines;
  push @outputlines, "";

  if (@log_lines) {

    my $earliest_year=3000;
    my $latest_year=0;
    my %authordata;
    my %authorline;

    # Get the commit blacklist to ignore
    my @blacklist=getblacklist();

    # Extract the author data and separate by year
    foreach ( @log_lines ) {

      my @fields=split(/ /,$_,3);
      my $commit=$fields[0];
      my $when=DateTime->from_epoch(epoch => $fields[1]);
      my $year=$when->year();
      my $author=$fields[2];

      my $count = true { /$commit/ } @blacklist;
      if ( $count >= 1 ) { next; };

      if ($year < $earliest_year) { $earliest_year=$year; };
      if ($year > $latest_year) { $latest_year=$year; };
      if ( $author ne "unknown" ) { push(@{$authordata{$year}}, $author); };
    };

    # Remove duplicates within a year, sort and transform to string
    foreach my $year (keys %authordata) {

      my @un=uniq(@{$authordata{$year}});
      $authorline{$year}=join(', ',sort_by { $_ } @un);

    };

    # Now deduplicate the years
    push @outputlines, "  Copyright $earliest_year       ".$authorline{$earliest_year};

    for ( my $year=$earliest_year+1; $year<=$latest_year; $year++) {

    if ( (defined $authorline{$year}) && (defined $authorline{$year-1}) ) {

      if ($authorline{$year-1} eq $authorline{$year}) {

        my $lastline=$outputlines[-1];
          $lastline=~ s/([0-9]{4})[\- ][0-9 ]{4}/$1-$year/;
          $outputlines[-1]=$lastline;
        } else {
          push @outputlines, "            $year       ".$authorline{$year};
        };

      } elsif ( defined $authorline{$year} ) {

        push @outputlines, "            $year       ".$authorline{$year};

      };
    };
    push @outputlines, "";
  };

  return @outputlines;
}

sub munge_files {
  my ($self) = @_;
  my $myv="git";
  if ( defined $Dist::Zilla::Plugin::AuthorsFromGit::VERSION ) { $myv=$Dist::Zilla::Plugin::AuthorsFromGit::VERSION; };
  $self->log([ 'extracting Git commit information, plugin version %s', $myv ]);
  my $git = Git::Wrapper->new(".");

  $self->munge_file($_, $git) for @{ $self->found_files };
}

sub munge_file {
  my ($self, $file, $git) = @_;

  my @gal=gitauthorlist($file,$git);

  return $self->munge_pod($file, @gal);
}

sub munge_pod {
  my ($self, $file, @gal) = @_;

  my @content = split /\n/, $file->content;

  require List::Util;
  List::Util->VERSION('1.33');

  for (0 .. $#content) {
    next until $content[$_] =~ /^=head1 COPYRIGHT AND LICENSE/;

    $_++; # move past the =head1 line itself
    $_++; # and past the subsequent empty line
    
    # Now we should have a line looking like
    #
    # "This software is copyright ... , see the git log."
    #
    # The string ", see the git log." is used as magic to trigger the plugin.
    # We check this format, replace ", see the git log.",
    # and insert the git information afterwards.
    
    if ($content[$_] =~ /^This software is copyright.*, see the git log\.$/ ) {    
    
      $content[$_] =~ s/, see the git log\.$/; in detail:/;
      splice @content, $_+1, 0, @gal;
    
    };

    my $content = join "\n", @content;
    $content .= "\n" if length $content;
    $file->content($content);
    return;

  }

}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SEE ALSO
#pod
#pod L<PkgVersion|Dist::Zilla::Plugin::PodVersion>,
#pod L<PkgVersion|Git::Wrapper>,
#pod L<PkgVersion|Lab::Measurement> for an application example
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AuthorsFromGit - Add per-file per-year copyright info to each Perl document

=head1 VERSION

version 0.005

=head1 SYNOPSIS

In dist.ini, set

  copyright_holder = the Foo-Bar team, see the git log
  ; [...]
  [PodWeaver]
  [AuthorsFromGit]

In weaver.ini, set

  [@NoAuthor]

Then a copyright section in each module is created as follows:

  COPYRIGHT AND LICENSE

  This software is copyright (c) 2017 by the Foo-Bar team; in detail:

  Copyright 2014-2015  A. N. Author
            2016       A. N. Author, O. Th. Erautor
            2017       O. Th. Erautor

with names and years extracted from the Git commit log of the specific module.

=head1 DESCRIPTION

This Dist::Zilla plugin is intended for large Perl distributions that have been
existing for some time, where maintainership has changed over the years, and
where different people have contributed to different parts of the code. It
provides a means to acknowledge the contribution of different people to
different modules, where it is not possible to resonably list them all in the
authors field of the entire distribution.

This is also to reflect that, independent of the chosen license terms, anyone
who contributes nontrivial code to an open source package retains copyright of
the contribution. Some legislatures (e.g. Germany) even provide no way of
"transferring" copyright, since it is always bound to the natural person who
conceived the code.

=head1 USAGE

Here, the usage in conjunction with the PodWeaver plugin is described. It should
be possible to use this module without it, but I haven't tested that yet. We
also assume that your working directory is a Git clone.

Assuming your distribution is called Foo-Bar, in dist.ini, then set

  copyright_holder = the Foo-Bar team, see the git log
  ; [...]
  [PodWeaver]
  [AuthorsFromGit]

The precise string ", see the git log" at the end of the copyright_holder line
is important since it triggers this plugin.

In case you do not have a weaver.ini yet, create one with the content

  [@NoAuthor]

This is identical to the default plugin bundle of Pod-Weaver, just that it will
not create a separate AUTHORS section. In case you already have a weaver.ini, 
make sure it does not generate any AUTHORS section.

During the build process, Dist::Zilla will then run "git log" for each processed
module and extract the list of authors of the module for each year. Then a 
copyright section in the POD of each module is created as follows:

  COPYRIGHT AND LICENSE

  This software is copyright (c) 2017 by the Foo::Bar team; in detail:

  Copyright 2014-2015  A. N. Author
            2016       A. N. Author, O. Th. Erautor
            2017       O. Th. Erautor

=head1 CONFIGURATION

Not much.

=head2 Excluding commits

In case you want to skip some commits which contain trivial, not
copyright-relevant changes ("increase version number", "perltidy"), create
a text file named .copyright-exclude in the main distribution directory. It
should contain exactly one git commit hash per line, nothing else.

Use with care, and only add your own commits!

=head1 KNOWN BUGS

There's something fishy with unicode.

=head1 AUTHOR

Andreas K. Huettel <dilfridge@gentoo.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Andreas K. Huettel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
