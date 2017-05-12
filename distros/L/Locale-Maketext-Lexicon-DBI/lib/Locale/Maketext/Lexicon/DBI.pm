package Locale::Maketext::Lexicon::DBI;

use strict;
use warnings;

use version; our $VERSION = qv("0.2.1");

sub parse {
    my ($class, %param) = @_;

    my $dbh = $param{dbh};
    my $sth = $dbh->prepare("SELECT lex_key, lex_value FROM lexicon WHERE lex = ? AND lang = ?");

    $sth->execute($param{lex}, $param{lang})
      or warn "Error while fetching the lexicon.  You may missed the incompatibility change in v0.2.0, see\n"
      . "  perldoc Locale::Maketext::Lexicon::DBI\nThe error was: "
      . $sth->errstr;

    my %lexicon;
    while (my ($key, $value) = $sth->fetchrow) {
        $lexicon{$key} = $value;
    }

    return \%lexicon;
}

1;

__END__

=head1 NAME

Locale::Maketext::Lexicon::DBI - Database based lexicon fetcher/parser

=head1 SYNOPSIS

Called via B<Locale::Maketext::Lexicon>:

    package Hello::I18N;
    use base 'Locale::Maketext';
    use DBI;
    my $dbh = DBI->connect($dsn, $user, $password, $attr);
    use Locale::Maketext::Lexicon {
        de => [ DBI => [ lang => 'de', lex => 'lex', dbh => $dbh ] ],
    };

=head1 DESCRIPTION

This module implements a perl-based C<DBI> fetcher/"parser" for
B<Locale::Maketext>.  It reads the lexicon from the database and
B<transforms nothing> but expect the placeholders to be C<[_1]>, C<[_2]>,
C<[_*]>, and so on, like L<Locale::Maketext> wants them to be.

=head1 PARAMETERS FOR C<Locale::Maketext::Lexicon>

Usually we define source PO or MO file(s), as we do in L<Locale::Maketext::Lexicon::Gettext>.
Here we don't have files but need some parameters to access and read the database.

All three parameters are essential!

=over

=item lang

Although we already defined the language as the key of the hash L<Locale::Maketext::Lexicon>
imports, the language needs to be defined once again for C<Locale::Maketext::Lexicon::DBI>
to select the right lexicon entries.

=item lex

This is an identifier (string) in the database so that the lexicon can be separated into more
lexicons (e.g. for different applications/areas) within one table.

=item dbh

C<Locale::Maketext::Lexicon::DBI> don't want to connect to the database each time it
should fetch the content.  This parameter contains the database handle created by L<DBI>.

=back

=head1 DB TABLE DEFINITION

This is a example table definition for PostgreSQL:

    CREATE TABLE lexicon (
      id serial NOT NULL,
      lang character varying(15) DEFAULT NULL::character varying,
      lex character varying(255) DEFAULT NULL::character varying,
      lex_key text,
      lex_value text,
      notes text,
      CONSTRAINT lexicon_pkey PRIMARY KEY (id)
    ) WITH (OIDS=FALSE);

You should easily adapt this to MySQL and other database systems.  Note that the
columns C<lang>, C<lex>, C<lex_key> and C<lex_value> are essential!  Every other column
can be defined by the user.  C<notes> is an optional column that can be a hint
for the translator.

=head1 INCOMPATIBILITY CHANGE IN v0.2.0

B<IMPORTANT!>  Read this if you are updating from a version prior to v0.2.0!

Version 0.2.0 fixes an issue when not using PostgreSQL as RDBMS, since C<key> and C<value>
may be reserved words.  You need to alter the table C<lexicon> as described
above in L</DB TABLE DEFINITION>: change C<key> to C<lex_key> and C<value> to C<lex_value>.

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>, L<DBI>

=head1 AUTHOR

Matthias Dietrich, C<< <perl@rainboxx.de> >>, http://www.rainboxx.de

=head1 THANKS TO

Octavian Râşniţă for Bugfixes

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 rainboxx Matthias Dietrich.  All Rights Reserved.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

