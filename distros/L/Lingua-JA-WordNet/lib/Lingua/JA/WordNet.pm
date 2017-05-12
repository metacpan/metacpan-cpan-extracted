package Lingua::JA::WordNet;

use 5.008_008;
use strict;
use warnings;

use DBI;
use Carp ();
use File::ShareDir  ();
use List::MoreUtils ();

our $VERSION = '0.21';

my $DB_FILE = 'wnjpn-1.1_and_synonyms-1.0.db';


sub _options
{
    return {
        data        => File::ShareDir::dist_file('Lingua-JA-WordNet', $DB_FILE),
        enable_utf8 => 0,
        verbose     => 0,
    };
}

sub new
{
    my $class = shift;

    my $options = $class->_options;

    if (scalar @_ == 1) { $options->{data} = shift; }
    else
    {
        my %args = @_;

        for my $key (keys %args)
        {
            if ( ! exists $options->{$key} ) { Carp::croak "Unknown option: '$key'"; }
            else                             { $options->{$key} = $args{$key};       }
        }
    }

    Carp::croak 'WordNet data file is not found' unless -f $options->{data};

    my $dbh = DBI->connect("dbi:SQLite:dbname=$options->{data}", '', '', {
        #Warn           => 0, # get rid of annoying disconnect message
        # The Warn attribute enables useful warnings for certain bad practices.
        # It is enabled by default and should only be disabled in rare circumstances.
        # (see http://search.cpan.org/dist/DBI/DBI.pm#Warn)

        RaiseError     => 1,
        PrintError     => 0,
        AutoCommit     => 0,
        sqlite_unicode => $options->{enable_utf8},
    });

    bless { dbh => $dbh, verbose => $options->{verbose} }, $class;
}

sub DESTROY { shift->{dbh}->disconnect; }

sub Word
{
    my ($self, $synset, $lang) = @_;

    $lang = 'jpn' unless defined $lang;

    my $sth
        = $self->{dbh}->prepare
        (
            'SELECT lemma FROM word JOIN sense ON word.wordid = sense.wordid
              WHERE synset     = ?
                AND sense.lang = ?'
        );

    $sth->execute($synset, $lang);

    my @words = map { $_->[0] =~ tr/_/ /; $_->[0]; } @{$sth->fetchall_arrayref};

    Carp::carp "Word: there are no words for $synset in $lang" if $self->{verbose} && ! scalar @words;

    return @words;
}

sub Synset
{
    my ($self, $word, $lang) = @_;

    $lang = 'jpn' unless defined $lang;

    my $sth
        = $self->{dbh}->prepare
        (
            'SELECT synset FROM word LEFT JOIN sense ON word.wordid = sense.wordid
              WHERE lemma      = ?
                AND sense.lang = ?'
        );

    $sth->execute($word, $lang);

    my @synsets = map {$_->[0]} @{$sth->fetchall_arrayref};

    Carp::carp "Synset: there are no synsets for '$word' in $lang" if $self->{verbose} && ! scalar @synsets;

    return @synsets;
}

sub SynPos
{
    my ($self, $word, $pos, $lang) = @_;

    $lang = 'jpn' unless defined $lang;

    my $sth
        = $self->{dbh}->prepare
        (
            'SELECT synset FROM word LEFT JOIN sense ON word.wordid = sense.wordid
              WHERE lemma      = ?
                AND word.pos   = ?
                AND sense.lang = ?'
        );

    $sth->execute($word, $pos, $lang);

    my @synsets = map {$_->[0]} @{$sth->fetchall_arrayref};

    Carp::carp "SynPos: there are no synsets for '$word' corresponding to '$pos' and '$lang'" if $self->{verbose} && ! scalar @synsets;

    return @synsets;
}

sub Pos
{
    my ($self, $synset) = @_;
    return $1 if $synset =~ /^[0-9]{8}-([arnv])$/;
    Carp::carp "Pos: '$synset' is wrong synset format" if $self->{verbose};
    return;
}

sub Rel
{
    my ($self, $synset, $rel) = @_;

    my $sth
        = $self->{dbh}->prepare
        (
            'SELECT synset2 FROM synlink
              WHERE synset1 = ?
                AND link    = ?'
        );

    $sth->execute($synset, $rel);

    my @synsets = map {$_->[0]} @{$sth->fetchall_arrayref};

    Carp::carp "Rel: there are no $rel links for $synset" if $self->{verbose} && ! scalar @synsets;

    return @synsets;
}

sub Def
{
    my ($self, $synset, $lang) = @_;

    $lang = 'jpn' unless defined $lang;

    my $sth
        = $self->{dbh}->prepare
        (
            'SELECT sid, def FROM synset_def
              WHERE synset = ?
                AND lang   = ?'
        );

    $sth->execute($synset, $lang);

    my @defs;

    while (my $row = $sth->fetchrow_arrayref)
    {
        my ($sid, $def) = @{$row};
        $defs[$sid] = $def;
    }

    Carp::carp "Def: there are no definition sentences for $synset in $lang" if $self->{verbose} && ! scalar @defs;

    return @defs;
}

sub Ex
{
    my ($self, $synset, $lang) = @_;

    $lang = 'jpn' unless defined $lang;

    my $sth
        = $self->{dbh}->prepare
        (
            'SELECT sid, def FROM synset_ex
              WHERE synset = ?
                AND lang   = ?'
        );

    $sth->execute($synset, $lang);

    my @exs;

    while (my $row = $sth->fetchrow_arrayref)
    {
        my ($sid, $ex) = @{$row};
        $exs[$sid] = $ex;
    }

    Carp::carp "Ex: there are no example sentences for $synset in $lang" if $self->{verbose} && ! scalar @exs;

    return @exs;
}

sub AllSynsets
{
    my $self = shift;
    my $sth = $self->{dbh}->prepare('SELECT synset FROM synset');
    $sth->execute;
    my @synsets = map {$_->[0]} @{$sth->fetchall_arrayref};
    return \@synsets;
}

sub WordID
{
    my ($self, $word, $pos, $lang) = @_;

    $word =~ tr/ /_/;
    $lang = 'jpn' unless defined $lang;

    my $sth
        = $self->{dbh}->prepare
        (
            'SELECT wordid FROM word
              WHERE lemma = ?
                AND pos   = ?
                AND lang  = ?'
        );

    $sth->execute($word, $pos, $lang);

    my ($wordid) = map {$_->[0]} @{$sth->fetchall_arrayref};

    Carp::carp "WordID: there is no WordID for '$word' corresponding to '$pos' and '$lang'" if $self->{verbose} && ! defined $wordid;

    return $wordid;
}

sub Synonym
{
    my ($self, $wordid) = @_;

    my $sth
        = $self->{dbh}->prepare
        (
            'SELECT lemma FROM word JOIN wordlink ON word.wordid = wordlink.wordid2
              WHERE wordid1 = ?
                AND link    = ?'
        );

    $sth->execute($wordid, 'syns');
    my @synonyms = map {$_->[0]} @{$sth->fetchall_arrayref};

    Carp::carp "Synonyms: there are no Synonyms for $wordid" if $self->{verbose} && ! scalar @synonyms;

    # 一応順番を保持したいのでハッシュスライスは使わない
    # uniq: The order of elements in the returned list is the same as in LIST.
    return List::MoreUtils::uniq @synonyms;
}

1;

__END__

=encoding utf8

=head1 NAME

Lingua::JA::WordNet - Perl OO interface to Japanese WordNet database

=for test_synopsis
my ($db_path, %config, $synset, $lang, $pos, $rel);

=head1 SYNOPSIS

  use Lingua::JA::WordNet;

  my $wn = Lingua::JA::WordNet->new;
  my @synsets = $wn->Synset('相撲');
  my @hypes   = $wn->Rel($synsets[0], 'hype');
  my @words   = $wn->Word($hypes[0]);

  print "$words[0]\n";
  # -> レスリング

  # Synonym method can access to Japanese WordNet Synonyms Database.
  my $wordID   = $wn->WordID('ねんねこ', 'n');
  my @synonyms = $wn->Synonym($wordID);

  print "@synonyms\n";
  # -> お休み ねね スリープ 就眠 御休み 眠り 睡り 睡眠

=head1 DESCRIPTION

Japanese WordNet is a semantic dictionary of Japanese.
Lingua::JA::WordNet is yet another Perl module to look up
entries in Japanese WordNet.

The original Perl module is WordNet::Multi.
WordNet::Multi is awkward to use and no longer maintained.
Because of this, I uploaded this module.

=head1 METHODS

=head2 $wn = new($db_path) or new(%config)

Creates a new Lingua::JA::WordNet instance.

  my $wn = Lingua::JA::WordNet->new(
      data        => $db_path, # default is File::ShareDir::dist_file('Lingua-JA-WordNet', 'wnjpn-1.1_and_synonyms-1.0.db')
      enable_utf8 => 1,        # default is 0 (see sqlite_unicode attribute of DBD::SQLite)
      verbose     => 0,        # default is 0 (all warnings are ignored)
  );

The data must be Japanese WordNet and English WordNet in an SQLite3 database.


=head2 @words = $wn->Word( $synset [, $lang] )

Returns the words corresponding to $synset and $lang.

=head2 @synsets = $wn->Synset( $word [, $lang] )

Returns the synsets corresponding to $word and $lang.

=head2 @synsets = $wn->SynPos( $word, $pos [, $lang] )

Returns the synsets corresponding to $word, $pos and $lang.

=head2 $pos = $wn->Pos($synset)

Returns the part of speech of $synset.

=head2 @synsets = $wn->Rel($synset, $rel)

Returns the relational synsets corresponding to $synset and $rel.

=head2 @defs = $wn->Def( $synset [, $lang] )

Returns the definition sentences corresponding to $synset and $lang.

=head2 @exs = $wn->Ex( $synset [, $lang] )

Returns the example sentences corresponding to $synset and $lang,

=head2 $allsynsets_arrayref = $wn->AllSynsets()

Returns all synsets.

=head2 $wordID = $wn->WordID( $word, $pos [, $lang] )

Returns the word ID corresponding to $word, $pos and $lang.

=head2 @synonyms = $wn->Synonym($wordID)

Returns the synonyms of $wordID.

This method works only under the bundled Japanese WordNet database file.


=head2 LANGUAGES

$lang can take 'jpn' or 'eng'. The default value is 'jpn'.


=head2 PARTS OF SPEECH

$pos can take the left side values of the following table.

  a|adjective
  r|adverb
  n|noun
  v|verb
  a|形容詞
  r|副詞
  n|名詞
  v|動詞

This is the result of the SQL query 'SELECT pos, def FROM pos_def'.


=head2 RELATIONS

$rel can take the left side values of the following table.

  also|See also
  syns|Synonyms
  hype|Hypernyms
  inst|Instances
  hypo|Hyponym
  hasi|Has Instance
  mero|Meronyms
  mmem|Meronyms --- Member
  msub|Meronyms --- Substance
  mprt|Meronyms --- Part
  holo|Holonyms
  hmem|Holonyms --- Member
  hsub|Holonyms --- Substance
  hprt|Holonyms -- Part
  attr|Attributes
  sim|Similar to
  enta|Entails
  caus|Causes
  dmnc|Domain --- Category
  dmnu|Domain --- Usage
  dmnr|Domain --- Region
  dmtc|In Domain --- Category
  dmtu|In Domain --- Usage
  dmtr|In Domain --- Region
  ants|Antonyms

This is the result of the SQL query 'SELECT link, def FROM link_def'.


=head1 Out of memory!

In rare cases, this error message is displayed during the installation of this library.
If this is displayed, please install this library manually. (RT#82276)


=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

Japanese WordNet: L<http://nlpwww.nict.go.jp/wn-ja/>

L<http://twitter.com/LinguaJAWordNet>

=head1 LICENSE

This library except the bundled WordNet database file is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The bundled WordNet database file complies with the following licenses:

=over 4

=item * For Japanese data: L<http://nlpwww.nict.go.jp/wn-ja/license.txt>

=item * For English data: L<http://wordnet.princeton.edu/wordnet/license/>

=back


=cut
