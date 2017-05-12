package Locale::Framework::SQL;

use strict;
use DBI;
use DBI::Const::GetInfoType;

our $VERSION='0.07';

my %cache;

sub new {
  my $class=shift;
  my $args={
	    DSN => undef,
	    DBUSER => undef,
	    DBPASS => "",
	    TABLE => "lang_translations",
	    @_
	    };


  my $dsn=$args->{"DSN"} or die "You need to specify a valid DSN for DBI (DSN => ...)";
  my $user=$args->{"DBUSER"} or die "You need to specify a database user (DBUSER => ...)";
  my $pass=$args->{"DBPASS"};

  my $self;

  $self->{"dsn"}=$dsn;
  $self->{"dbh"}=DBI->connect($dsn,$user,$pass);
  $self->{"dbh"}->{"PrintError"}=0;
  $self->{"table"}=$args->{"TABLE"} or die "You need to specify a valid table name (TABLE => ...)";
  $self->{"status"}="none";

  my $table=$self->{"table"};

  bless $self,$class;

  { # Check existence

    my $sth=$self->{"dbh"}->prepare("SELECT COUNT(txt) FROM $table");
    my $dbh=$self->{"dbh"};

    if (not $sth->execute()) {
      $sth->finish();

      my $driver=lc($dbh->{Driver}->{Name});

      if ($driver eq "pg") {
	$self->{"dbh"}->do("CREATE TABLE $table (txt varchar, lang varchar(32), translation varchar, translated numeric(1))");
	$self->{"dbh"}->do("CREATE INDEX $table"."_idx ON $table(lang,txt)");
      }
      elsif ($driver eq "mysql") {
	$self->{"dbh"}->do("CREATE TABLE $table (txt text, lang varchar(32), translation text, translated numeric(1))");
	$self->{"dbh"}->do("CREATE INDEX $table"."_idx ON $table(lang,txt(200))");
      }
      elsif ($driver eq "sqlite") {
	$self->{"dbh"}->do("CREATE TABLE $table (txt text, lang varchar(32), translation text, translated numeric(1))");
	$self->{"dbh"}->do("CREATE INDEX $table"."_idx ON $table(lang,txt)");
      }
      else {
	die "Cannot create  table $table (txt varchar(BIG), lang varchar(32), translation varchar(big),translated numeric(1))\n".
	    "I don't know this database system '$driver'";
      }
    }
    else {
      $sth->finish();
    }
  }

return $self;
}

sub DESTROY {
  my $self=shift;
  $self->{"dbh"}->disconnect();
}

sub translate {
  my $self=shift;
  my $lang=shift;
  my $text=shift;

  my $dbh=$self->{"dbh"};
  my $table=$self->{"table"};

  if ($lang eq "") { return $text; }
  else {
    if (exists $cache{"$lang && $text"}) { 
      return $cache{"$lang && $text"};
    }
    else {
      my $sth=$dbh->prepare("SELECT translation FROM $table WHERE txt='$text' AND lang='$lang'");
      $sth->execute();
      if ($sth->rows() gt 0) {
	my @r=$sth->fetchrow_array();
	$cache{"$lang && $text"}=shift @r;
	$sth->finish();
	return $self->translate($lang,$text);
      }
      else {
	$cache{"$lang && $text"}=$text;
	$sth->finish();
	$dbh->do("INSERT INTO $table (translation, lang, txt, translated) VALUES ('$text','$lang','$text',0)");
	return $self->translate($lang,$text);
      }
    }
  }
}

sub clear_cache {
    %cache = ();
}

sub set_translation {
  my $self=shift;
  my $lang=shift;
  my $text=shift;
  my $translation=shift;

  if ($lang eq "") {
    die "Cannot set a translation for an empty language";
  }

  my $dbh=$self->{"dbh"};
  my $table=$self->{"table"};

  my $sth=$dbh->prepare("SELECT translation FROM $table WHERE txt='$text' AND lang='$lang'");
  $sth->execute();
  if ($sth->rows() gt 0) {
    $sth->finish();
    $dbh->do("UPDATE $table SET translation='$translation', translated=1 WHERE txt='$text' AND lang='$lang'");
  }
  else {
    $sth->finish();
    $dbh->do("INSERT INTO $table (translation, lang, txt, translated) VALUES ('$text','$lang','$text',0)");
  }

  $cache{"$lang && $text"}=$translation;

return 1;
}

1;

__END__

=head1 NAME

Locale::Framework::SQL - An SQL Backend for Locale::Framework

=head1 SYNOPSIS

  use Locale::Framework;
  use Locale::Framework::SQL;
  
  Locale::Framework::init(new Locale::Framework::SQL(
                               DSN => "dbi:Pg:dbname=zclass;host=localhost", 
                               DBUSER => "test", 
                               DBPASS => "testpass", 
                               [TABLE => "testtrans"]));
  
  Locale::Framework::language("en");

  print _T("This is a test");

  Locale::Framework::language("nl");
  
  print _T("This is a test");

=head1 ABSTRACT

This module provides an SQL backend for the Locale::Framework internationalization
module.

=head1 DESCRIPTION

=head2 C<new(DSN =E<gt> ..., DBUSER =E<gt> ..., DBPASS =E<gt> ..., [TABLE =E<gt> ...])> --E<gt> Locale::Framework::SQL

Instantiates a new backend object with given DSN, user and password.
It creates, if not already existent, table 'lang_translations' and 
index 'lang_translations_idx' in the given database in DSN. TABLE defaults
to C<'lang_translations'>.

=head2 C<translate(language,text)> --E<gt> string

This function looks up a translation for the tuple (language, text)
in the database. If it doesn't find one, it inserts the tuple in
the database with translation 'text'. 

This function will cache all lookups in the database. So after a running
a program for a while, there won't be a lot of database access anymore 
for translations. This also means, that a updating translations in the
database will probably not result in updated translations in the application.

=head2 C<set_translation(language,text,translation)> --E<gt> boolean

This function looks up the tuple (language,text) in the database.
If it does exist, it updates the translation for this field. 
Otherwise, it inserts the translation.

This function will cache the translation. Function always returns C<true>
(i.e. 1).

=head2 C<clear_cache()> --E<gt> void

This function will clear the cache of translations.

=head1 BUGS

This module has only been tested with PostgreSQL and MySQL.

=head1 SEE ALSO

L<Locale::Framework|Locale::Framework>.

=head1 AUTHOR

Hans Oesterholt-Dijkema <oesterhol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under LGPL terms.

=cut
