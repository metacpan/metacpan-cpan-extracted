package HiD::Generator::GitRepositories;
# ABSTRACT: HiD GitRepository listing generator
use Moose;
with 'HiD::Generator';
use HiD::Generator::GitRepositories::GitRepository;
use File::Basename;
use Text::Markdown;
use Try::Tiny;
use DateTime;
use DateTime::TimeZone;
use DBI;
use DBD::SQLite;
use DBIx::Migration;
use File::ShareDir ':ALL';
use Text::VimColor;
use Image::WordCloud;
use strict;
use warnings;

our $VERSION = "0.3";

has 'dbh' => (is=>'rw');

has 'dbfile' => (is => 'rw');

has 'repo_dir' => (is => 'rw');

has 'list_layout' => (is => 'rw');

has 'repo_layout' => (is => 'rw');

has 'index_layout' => (is => 'rw');

has 'base_url' => (is => 'rw');


has 'destination' => (is => 'rw');

has 'share_dir'  => (is => 'rw');

has 'git_base_http_url' => (is => 'rw');


has 'git_base_ssh_url' => (is => 'rw');

sub migrate
{
  my $self = shift;

  die("No database file available") unless $self->dbfile();
  my $m = DBIx::Migration->new(
    {
        dsn => "dbi:SQLite:dbname=" . $self->dbfile(),
        dir => $self->share_dir() . "/migration/"
    }
  );

  if ( $m->version != 1 )
  {
    $m->migrate(1);
  }

}

sub refresh_database
{
  my $self = shift;

  my $sth = $self->dbh()->prepare("SELECT dir, reponame from repository");
  $sth->execute();

  while (my $row=$sth->fetchrow_hashref)
  {
    if (! -d $row->{dir})
    {
      my $sth2 = $self->dbh()->prepare("DELETE FROM repository where reponame=?");
      $sth2->execute($row->{reponame});
      $sth2->finish;

      $sth2 = $self->dbh()->prepare("DELETE FROM repository_tags where reponame=?");
      $sth2->execute($row->{reponame});
      $sth2->finish;

      $sth2 = $self->dbh()->prepare("DELETE FROM repository_languages where reponame=?");
      $sth2->execute($row->{reponame});
      $sth2->finish;

    }
  }

  $sth->finish;

}


sub removeRepo
{
  my $self      = shift;
  my $reponame  = shift;


  my $sth = $self->dbh()->prepare("DELETE FROM repository where reponame=?");
  $sth->execute($reponame);
  $sth->finish;

  $sth = $self->dbh()->prepare("DELETE FROM repository_tags where reponame=?");
  $sth->execute($reponame);
  $sth->finish;

  $sth = $self->dbh()->prepare("DELETE FROM repository_languages where reponame=?");
  $sth->execute($reponame);
  $sth->finish;

}

sub addRepo
{
  my $self        = shift;
  my $repo        = shift;

  my $sth = $self->dbh()->prepare("INSERT into repository(reponame, dir, description, lastchange) VALUES(?,?,?,?)");
  $sth->execute($repo->name, $repo->git_dir, $repo->description, $repo->lastChange()->epoch);
  $sth->finish;

  for my $t ($repo->tags)
  {
    $sth = $self->dbh()->prepare("INSERT into repository_tags(reponame, tag) VALUES(?,?)");
    $sth->execute($repo->name, $t);
    $sth->finish;
  }

  for my $l (@{$repo->languages})
  {
    $sth = $self->dbh()->prepare("INSERT into repository_languages(reponame, language) VALUES(?,?)");
    $sth->execute($repo->name, $l);
    $sth->finish;
  }

}


sub getRepos
{
  my $self = shift;
  my $order = shift || "name";
  my $dir   = shift || "DESC";
  my @repos;

  my $sth = $self->dbh()->prepare("SELECT repository.reponame as name, repository.dir as dir,
                                          repository.description as description,
                                          repository.lastchange as lastchange from repository order by " . $order . " ". $dir );
  $sth->execute();

  my $tz=DateTime::TimeZone->new( name => 'local' );
  my $count=0;

  while (my $repo = $sth->fetchrow_hashref)
  {
    $count++;
    $repo->{count}=$count;
    $repo->{lastchange} = DateTime->from_epoch( epoch => $repo->{lastchange}, time_zone=>$tz)->ymd();
    my $sth2 = $self->dbh()->prepare("SELECT tag from repository_tags where reponame = ?");
    $sth2->execute($repo->{name});

    my @tags;
    while (my $row=$sth2->fetchrow_hashref)
    {
        push(@tags, $row->{tag});
    }
    $sth2->finish;
    $repo->{tags}=\@tags;

    $sth2 = $self->dbh()->prepare("SELECT language from repository_languages where reponame = ?");
    $sth2->execute($repo->{name});

    my @languages;
    while (my $row=$sth2->fetchrow_hashref)
    {
        push(@languages, $row->{language});
    }
    $sth2->finish;
    $repo->{languages}=\@languages;


    push(@repos, $repo);
  }

  $sth->finish;

  return \@repos;
}

sub getAllTags
{
  my $self = shift;
  my @tags;

  my $sth = $self->dbh()->prepare("SELECT tag from repository_tags");
  $sth->execute();
  while (my $row = $sth->fetchrow_hashref)
  {
    push(@tags, $row->{tag});
  }

  return @tags;
}

sub getAllLangs
{
  my $self = shift;
  my @langs;

  my $sth = $self->dbh()->prepare("SELECT language from repository_languages");
  $sth->execute();
  while (my $row = $sth->fetchrow_hashref)
  {
    push(@langs, $row->{language});
  }

  return @langs;
}

sub generate {
  my( $self , $site ) = @_;

  # do nothing if generation is not enabled
  return unless $site->config->{gitrepositories}{generate};

  $self->share_dir(dist_dir('HiD-Generator-GitRepositories'));

  # fetch the directory containing all the git repositories from the config file
  $self->repo_dir($site->config->{gitrepositories}{dir});
  die "directory holding the git repositories not given" unless $self->repo_dir();

  # check if repository directory exist
  die("GitRepository directory does not exist") unless -d $self->repo_dir();

  # fetch the list layout file from config file
  $self->list_layout($site->config->{gitrepositories}{list_layout});
  die "Must define gitrepositories.list_layout in config" unless $self->list_layout();

  # fetch the repo layout file from config file
  $self->repo_layout($site->config->{gitrepositories}{repo_layout});
  die "Must define gitrepositories.repo_layout in config" unless $self->repo_layout();

  # fetch the index layout file from config file
  $self->index_layout($site->config->{gitrepositories}{index_layout});
  die "Must define gitrepositories.index_layout in config" unless $self->index_layout();

  # fetch the base url from the config file
  $self->base_url($site->config->{gitrepositories}{url});
  $self->base_url('repositories/') unless $self->base_url();

  # fetch the destination from the config file
  $self->destination($site->config->{gitrepositories}{destination});
  $self->destination($site->destination) unless $self->destination();
  $self->_create_destination_directory_if_needed( $self->destination() );

  # fetch the database file from config file
  $self->dbfile($site->config->{gitrepositories}{dbfile});
  $self->dbfile($site->config->{source} ."/_gitrepos.db") unless $self->dbfile();

  # fetch the git_base_http_url from config file
  $self->git_base_http_url($site->config->{gitrepositories}{git_base_http_url});

  # fetch the git_base_ssh_url from config file
  $self->git_base_ssh_url($site->config->{gitrepositories}{git_base_ssh_url});

  # open the database file
  $self->dbh(DBI->connect("dbi:SQLite:dbname=" . $self->dbfile(),"",""));
  die("Can not connect to database " . $self->dbfile()) unless $self->dbh();

  # update database schema
  $self->migrate();

  # remove non existing repositories from database
  $self->refresh_database();

  #search all repositories within repo_dir
  my @dirs = glob($self->repo_dir() . "/*");

  # array for all repos which should be reprocessed
  my @repos;


  for my $d (@dirs)
  {

    my $gitRepo;

    # check if the directory is a git repository and return a git repository object
    try {
      $gitRepo = HiD::Generator::GitRepositories::GitRepository->new(
          git_dir     => $d
      );
      } catch {
        warn "caught error: $_"; # not $@
      };

    if (defined($gitRepo)) {
      if ($gitRepo->hasMetaData) {

        my $generate=1;
        # check if the file already exist and ist newer than last repo change
        if ( -e $self->destination() . "/". $self->base_url() . "index.html")
        {
          open my $fh,"<", $self->destination() . "/" . $self->base_url() . "index.html";
          my $epoch_timestamp = (stat($fh))[9];
          close $fh;
          my $tz=DateTime::TimeZone->new( name => 'local' );
          my $file  = DateTime->from_epoch( epoch => $epoch_timestamp, time_zone=>$tz );
          my $repo  = $gitRepo->lastChange();

          # if file is newer than last change do not generate repo files
          if (DateTime->compare( $file, $repo ) == 1)
          {
            $generate=0;
          }
        }

        if ($generate)
        {
          # for regeneration we have to first remove repo from database
          $self->removeRepo($gitRepo->name);

          # parse for programming languages
          $gitRepo->parse_languages();

          # now update repository data in database
          $self->addRepo($gitRepo);

          push(@repos, $gitRepo);
        }
      }
    }
  }

  my $dbrepos = $self->getRepos();
  my $nrrepos = @{$dbrepos};

  #create word cloud image for all tags
  my $font_dir = "/usr/share/fonts/truetype/freefont/";
  my $wc_tags = Image::WordCloud->new(font_path => $font_dir, background=>[255,255,255], font=>"FreeSans.ttf", image_size=>[300,300] );
  $wc_tags->words(join ( ' ', $self->getAllTags ));
  my $gd_tags = $wc_tags->cloud();
  #make image background transparent
  my $white = $gd_tags->colorAllocate(255,255,255);
  $gd_tags->transparent($white);

  readpipe("mkdir -p " . $self->destination() . "/images/");
  open(my $fh, '>', $self->destination()."/images/wc_tags.png");
  binmode $fh;
  print $fh $gd_tags->png();
  close($fh);

  #create word cloud image for all languages
  my $wc_langs = Image::WordCloud->new(font_path => $font_dir, background=>[255,255,255], font=>"FreeSans.ttf", image_size=>[300,300] );
  $wc_langs->words(join ( ' ', $self->getAllLangs ));
  my $gd_langs = $wc_langs->cloud();
  #make image background transparent
  $white = $gd_langs->colorAllocate(255,255,255);
  $gd_langs->transparent($white);

  open($fh, '>', $self->destination()."/images/wc_langs.png");
  binmode $fh;
  print $fh $gd_langs->png();
  close($fh);


  # create the index.htm page
  my $index = HiD::Page->new({
    dest_dir       => $self->destination(),
    hid            => $site,
    url            => "/index.htm",
    input_filename => $self->index_layout(),
    layouts        => $site->layouts,
  });
  my $last_repos = $self->getRepos("lastchange", "DESC");
  splice @{$last_repos}, 6;

  $index->metadata->{repos} = $last_repos;
  $index->metadata->{nrrepos} = $nrrepos;
  $index->metadata->{tagcloud}="/images/wc_tags.png";
  $index->metadata->{langcloud}="/images/wc_langs.png";
  $site->add_input( "INDEX" => 'page' );
  $site->add_object( $index );
  $site->INFO( "* Injected Index Page");

  # create the repository listing page
  my $page = HiD::Page->new({
    dest_dir       => $self->destination(),
    hid            => $site,
    url            => $self->base_url(),
    input_filename => $self->list_layout(),
    layouts        => $site->layouts,
  });

  $page->metadata->{repositories} = $dbrepos;
  $page->metadata->{nrrepos} = $nrrepos;

  $site->add_input( "Repositories" => 'page' );
  $site->add_object( $page );

  $site->INFO( "* Injected GitRepository Listing");

  # now create a page for each repository
  for my $repo (@repos)
  {
    for my $branch (@{$repo->branches})
    {
      $self->genBranchTree($site, $self->base_url(), $self->destination(), $self->repo_layout(), $repo, $branch->{name},"");
    }

  }


}

sub genBranchTree
{
  my $self        = shift;
  my $site        = shift;
  my $url         = shift;
  my $destination = shift;
  my $page_file   = shift;
  my $repo        = shift;
  my $branch      = shift;
  my $base        = shift;
  my $root        = shift || $base;
  my $type        = shift || "tree";
  my $ref         = shift;


  #only generate tree of branch if last branch activity is newer than existing files

  if($type eq "tree") {
    my $page = HiD::Page->new({
      dest_dir       => $self->destination() ,
      hid            => $site,
      url            => $self->base_url() . "/" . $repo->name ."/" . $branch . "/" . $root . "/" ,
      input_filename => $self->repo_layout() ,
      layouts        => $site->layouts ,
    });

    $page->metadata->{repository} = $repo;
    my @tree = $repo->getTree($branch, $root);
    if ($root ne $base)
    {
      my $entry = {
        name => "..",
        path => "..",
        type => "tree",
        date => 0
      };
      unshift(@tree, $entry);
    }
    my @log=$repo->getFileLog($branch, $root, 1);
    $page->metadata->{latest_commit}=$log[0];
    $page->metadata->{tree} = \@tree;
    $page->metadata->{currentroot} = $root;
    $page->metadata->{currentbranch} = $branch;
    $page->metadata->{branches} = $repo->branches;
    $page->metadata->{git_base_http_url} = $self->git_base_http_url();
    $page->metadata->{git_base_ssh_url} = $self->git_base_ssh_url();
    my $dbrepos = $self->getRepos();
    my $nrrepos = @{$dbrepos};
    $page->metadata->{nrrepos} = $nrrepos;
    # check for a readme.md file in current tree and render it
    for my $t (@tree)
    {
      if (lc($t->{name}) eq "readme.md")
      {
        my $m = Text::Markdown->new;
        my $html = $m->markdown($repo->getBlob($t->{ref}));
        $page->metadata->{content_name} = $t->{name};
        $page->metadata->{content} = $html;
      }
    }

    $site->add_input( "Repositories" => 'page' );
    $site->add_object( $page );
    $site->INFO( "* Injected GitRepository page for repo " . $repo->name . " Branch: " . $branch . " Path: " . $root);

    for my $t (@tree)
    {
        next unless $t->{name} ne "..";
        my $newroot=$base . $t->{path} . "/";
        $self->genBranchTree($site, $url, $destination, $page_file, $repo, $branch,$base, $newroot, $t->{type}, $t->{ref});
    }
 }
 else
 {
   my $page = HiD::Page->new({
     dest_dir       => $self->destination(),
     hid            => $site ,
     url            => $self->base_url() . "/" . $repo->name ."/" . $branch . "/" . $root . "/" ,
     input_filename => $self->repo_layout() ,
     layouts        => $site->layouts ,
   });
   $page->metadata->{repository} = $repo;
   $page->metadata->{currentroot} = $root;
   $page->metadata->{currentbranch} = $branch;
   my $dbrepos = $self->getRepos();
   my $nrrepos = @{$dbrepos};
   $page->metadata->{nrrepos} = $nrrepos;

   my $file=$root;
   $file =~s/\/$//;
   $file="/tmp/" . fileparse($file);

   my $blob=$repo->getBlob($ref);
   $blob=~s/^[\n\s]*//g;
   my $syntax;
   my $html;
   if (length($blob) < 100000)
   {
     open my $tmp, ">", $file;
     print $tmp $blob;
     close $tmp;
     $syntax = Text::VimColor->new(
     file => $file,
     );
     $html=$syntax->html();
   } else {
     $html=$blob;
   }

   $page->metadata->{content_name} = $root;
   $page->metadata->{content_type} = "code";
   $page->metadata->{content} = $html;
   $page->metadata->{git_base_http_url} = $self->git_base_http_url();
   $page->metadata->{git_base_ssh_url} = $self->git_base_ssh_url();

   $site->add_input( "Repositories" => 'page' );
   $site->add_object( $page );
   $site->INFO( "* Injected GitRepository page for repo " . $repo->name . " Branch: " . $branch . " Path: " . $root);
 }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::Generator::GitRepositories - HiD GitRepository listing generator

=head1 VERSION

version 0.3

=head1 ATTRIBUTES

=head2 dbh

attribute containing the database handle to the sqlite database

=head2 dbfile

the sqlite database file used for caching

=head2 repo_dir

directory containing all the git repositories

=head2 list_layout

the layout file for generating the repository listing

=head2 repo_layout

the layout file for generating all the repository pages

=head2 index_layout

the layout file for generating all the index.htm

=head2 base_url

the base url for all the repositories

=head2 destination

the destination to which directory to generate the website

=head2 share_dir

path to the share distribution directory

=head2 git_base_http_url

the base http url for accessing the git repository through http

=head2 git_base_ssh_url

the base ssh url for accessing the git repository through ssh

=head1 METHODS

=head2 migrate

migrate database layouts

=head2 refresh_database

remove repository information of non existing repositories

=head2 removeRepo

remove the given repo from the database

=head2 addRepo

add the given Repo and the information to the database

=head2 getRepos

fetch all repos from database and return as an array from hashrefs

=head2 getAllTags

fetch all tags from database and return as an array

=head2 getAllLangs

fetch all languages from database and return as an array

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
