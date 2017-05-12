package Email::AutoReply::DB::BerkeleyDB;
our $rcsid = '$Id: BerkeleyDB.pm 3002 2008-06-05 20:23:24Z adam $';

use strict;
use warnings;

use Email::AutoReply::DB '-Base';
use Email::AutoReply::Recipient;
use BerkeleyDB;
use Carp qw(confess);

field 'email_autoreply_settings_dir';
field 'cachedb_file' => "replied_cache.db";
field 'cachedb_path'; # a path, not ending in a path separator
field '_db'; # the reference to the actual tied hash

sub new {
  $self = super;
  $self->_check_path_available;
  $self->_init_db;
  return $self;
}

sub _check_path_available {
  my $dir = $self->email_autoreply_settings_dir;
  defined($dir) or confess "must pass in email_autoreply_settings_dir";
  $self->cachedb_path($self->email_autoreply_settings_dir);
}

sub _init_db {
  my %autoreply_cache;
  my $filename = $self->cachedb_path . '/' . $self->cachedb_file;
  tie %autoreply_cache, 'BerkeleyDB::Hash',
    -Filename => $filename,
    -Flags => DB_CREATE|DB_INIT_LOCK,
    or die "Cannot open file $filename: $! $BerkeleyDB::Error\n";
  $self->_db(\%autoreply_cache);
}

sub store {
  my $input_type = 'Email::AutoReply::Recipient';
  ref $_[0] eq $input_type or confess "input object must be an $input_type";
  $_[0]->email && $_[0]->timestamp or confess "invalid input";
  $self->_db->{$_[0]->email} = $_[0]->timestamp;
}

#  INPUT: string to search for
# OUTPUT: Email::AutoReply::Recipient object, or zero
sub fetch {
  my $timestamp = $self->_db->{$_[0]};
  my $rv = 0;
  if ($timestamp) {
    $rv = Email::AutoReply::Recipient->new(
      email => $_[0], timestamp => $timestamp
    );
  }
  return $rv;
}

#  INPUT: 
# OUTPUT: list of Email::AutoReply::Recipient objects, or an empty list
sub fetch_all {
  return keys %{ $self->_db };
}

return 1;
__END__

=head1 NAME

Email::AutoReply::DB::BerkeleyDB - Berkeley DB autoreply cache database

=head1 DESCRIPTION

Please see L<Email::AutoReply::DB>, the interface this class implements.

=head1 AUTHOR

Adam Monsen, <haircut@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 by Adam Monsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
