package Lingua::ZH::CEDICT::MySQL;

# Copyright (c) 2002 Christian Renz <crenz@web42.com>
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict;
use warnings;
use vars qw($VERSION @ISA);
use Net::MySQL;

$VERSION = '0.02';
@ISA = qw(Lingua::ZH::CEDICT);

# (mysql)
# host       =>
# port       =>
# db         =>
# user       =>
# password   =>
# prefix     => (prefix for tables, default: CEDICT)
sub new {
    my $class = shift;
    my $self = +{@_};

    $self->{host}   ||= "localhost";
    $self->{port}   ||= "3306";
    $self->{prefix} ||= "CEDICT";

    bless $self, $class;
}

sub _connect {
    my ($self) = @_;
    return if defined $self->{mysql};

    $self->{mysql} = Net::MySQL->new(
        hostname => $self->{host},
        database => $self->{db},
        user     => $self->{user},
        password => $self->{password});
    die $self->{mysql}->get_error_message . "\n"
        if ($self->{mysql}->is_error);
}

sub init {
    my ($self) = @_;

    $self->_connect();
}

sub _create_tables {
    my ($self) = @_;

    $self->{mysql}->query("drop table $self->{prefix}_entries_tmp");
    $self->{mysql}->query(<<EOQ);
create table $self->{prefix}_entries_tmp (
    id int unsigned not null,
    zh_trad char(30) not null,
    zh_simp char(30) not null,
    pinyin char(75) not null,
    toneless_pinyin char(60) not null,
    english char (250) not null,

    primary key(id),
    fulltext(zh_trad, zh_simp, pinyin, toneless_pinyin, english))
type = MYISAM
EOQ
    die $self->{mysql}->get_error_message . "\n"
        if ($self->{mysql}->is_error);
}

sub _move_tmp_tables {
    my ($self) = @_;

    $self->{mysql}->query("drop table $self->{prefix}_entries");
    $self->{mysql}->query("rename table $self->{prefix}_entries_tmp to $self->{prefix}_entries;");
    die $self->{mysql}->get_error_message . "\n"
        if ($self->{mysql}->is_error);
}

sub importData {
    my ($self, $dict) = @_;

    $self->_connect();
    $self->_create_tables;
    for (0..($dict->numEntries - 1)) {
        my $e = $dict->entry($_);

        $self->{mysql}->query(<<EOQ);
INSERT INTO $self->{prefix}_entries_tmp
            (id, zh_trad, zh_simp, pinyin, toneless_pinyin, english)
VALUES ('$_', '$e->[0]', '$e->[1]', '$e->[2]', '$e->[3]', '$e->[4]')
EOQ
        print STDERR "$_\n" if ($_ % 100 == 0);
    }
    die $self->{mysql}->get_error_message . "\n"
        if ($self->{mysql}->is_error);
    $self->_move_tmp_tables;
}

sub numRows {
    my ($self) = @_;

    return $self->{mysql}->get_affected_rows_length();
}

# Functions for accessing the dictionary ************************************

sub startMatch {
    my ($self, $key) = @_;

    $self->{mysql}->query(<<EOQ);
SELECT   zh_trad, zh_simp, pinyin, english
FROM     $self->{prefix}_entries
WHERE    (zh_trad like '%$key\%' or
          zh_simp like '%$key\%' or
          pinyin regexp '[[:<:]]$key\[[:>:]]' or
          toneless_pinyin regexp '[[:<:]]$key\[[:>:]]' or
          english regexp '[[:<:]]$key\[[:>:]]')
EOQ
    die $self->{mysql}->get_error_message . "\n"
        if ($self->{mysql}->is_error);

    if ($self->{mysql}->has_selected_record) {
        $self->{iterator} = $self->{mysql}->create_record_iterator;
    } else {
        $self->{iterator} = undef;
    }

    return $self->{iterator};
}

sub match {
    my ($self) = @_;

    return $self->{iterator}->each;
}

sub startFind {
    my ($self, $key) = @_;

    $self->{mysql}->query(<<EOQ);
SELECT   zh_trad, zh_simp, pinyin, english
FROM     $self->{prefix}_entries
WHERE    (zh_trad = '$key' or
          zh_simp = '$key' or
          pinyin = '$key' or
          toneless_pinyin = '$key' or
          english = '$key')
EOQ
    die $self->{mysql}->get_error_message . "\n"
        if ($self->{mysql}->is_error);

    if ($self->{mysql}->has_selected_record) {
        $self->{iterator} = $self->{mysql}->create_record_iterator;
    } else {
        $self->{iterator} = undef;
    }

    return $self->{iterator};
}

sub find {
    my ($self) = @_;

    return $self->{iterator}->each;
}

1;
__END__

=head1 NAME

Lingua::ZH::CEDICT::MySQL - MySQL interface for Lingua::ZH::CEDICT

=head1 SYNOPSIS

  use Lingua::ZH::CEDICT;

  $dict = Lingua::ZH::CEDICT->new(source   => "MySQL",
                                  host     => "localhost",
                                  port     => "3306",
                                  db       => "dict",
                                  user     => "frederik",
                                  password => "pickeldie",
                                  prefix   => "CEDICT");

  # Connect to MySQL server and search something
  $dict->init();

  $dict->startMatch('house');
  while (my $e = $dict->match()) {
      #      trad    simp    pinyin pinyin w/o tones  english
      print "$e->[0] $e->[1] [$e->[2] / $e->[3]] $e->[4]\n";
  }

  # or import from textfile and store in database for future use
  # (you could also use storable for import)
  $tdict = Lingua::ZH::CEDICT->new{src => "Textfile");
  $dict->importData($tdict);

=head1 DESCRIPTION

This module uses a MySQL database to store the dictionary data.
Nice for dictionary websites.
Check out L<http://www.web42.com/zidian/> for an example.

=head1 METHODS

=over 4

=item C<startMatch($key)>

Performs a C<select> on the database and returns an enumerator. You can
either use it or call match.

  my $enum = startMatch($key);
  while (my $e = $enum->each()) {
      # ...
  }

If you are surprised by the matches, take a look at the source code
to see what the C<select> does.

Note that it is your responsibility to ensure that the key doesn't 
contain malicious input. I suggest using something like

  $key =~ s/[^\p{L}\w\d]//g;

(This requires perl 5.6.1)

=item C<match()>

Provided for compatibility with the other modules. Uses the
enumerator generated by C<startMatch>.

=back

=head1 PREREQUISITES

L<Net::MySQL> for the connections to MySQL.

L<Lingua::ZH::CEDICT>. (Although you can choose to circumvent it for performance reasons).

=head1 AUTHOR

Christian Renz, E<lt>crenz@web42.comE<gt>

=head1 LICENSE

Copyright (C) 2002 Christian Renz. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Lingua::ZH::CEDICT>. L<Net::MySQL>. L<http://www.web42.com/zidian/>

=cut
