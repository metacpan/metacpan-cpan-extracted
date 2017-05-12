package Labyrinth::Users;

use warnings;
use strict;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Users - Generic User Management for Labyrinth

=head1 DESCRIPTION

Contains generic user functionality that are required across the Labyrinth
framework, and may be used within plugins.

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    'all' => [ qw( GetUser UserName UserID FreshPassword PasswordCheck UserSelect ) ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

# -------------------------------------
# Library Modules

use Labyrinth::Audit;
use Labyrinth::Globals;
use Labyrinth::DBUtils;
use Labyrinth::MLUtils;
use Labyrinth::Variables;

use Session::Token;

# -------------------------------------
# Variables

my (%users,%userids);  # quick lookup hashes

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item GetUser($id)

Given a user id, performs a database lookup, unless a previous lookup for the
same id has already been requested.

=item UserName($id)

Given a user id, returns the user's name.

=item UserID

Given a user's name (real name or nick name), returns the user id.

=item FreshPassword

Returns a generated password string.

=item PasswordCheck

Checks the given password against the required rules.

=back

=cut

sub GetUser {
    my $uid = shift;
    return  unless($uid);

    $users{$uid} ||= do {
        my @rows = $dbi->GetQuery('hash','GetUserByID',$uid);
        $rows[0]    if(@rows);
    };

    return $users{$uid};
}

sub UserName {
    my $uid = shift;
    return  unless($uid);

    my $user = GetUser($uid);
    return $user->{realname} || $user->{nickname};
}

sub UserID {
    my $name = shift;
    return  unless($name);

    $userids{$name} ||= do {
        my @rows = $dbi->GetQuery('hash','GetUserByName',$name);
        return  unless(@rows);
        $users{$rows[0]->{userid}} ||= $rows[0];
        $rows[0]->{userid};
    };

    return $userids{$name};
}

sub FreshPassword {
    my $gen = Session::Token->new(length => 10);
    return $gen->get();
}

sub PasswordCheck {
    my $password = shift || return 6;
    my $plen = length $password;

    return 4    if($password =~ /\s/);
    return 1    if($settings{minpasslen} && $plen < $settings{minpasslen});
    return 2    if($settings{maxpasslen} && $plen > $settings{maxpasslen});

    # Check unique characters
    my @chars = split //,$password ;
    my %unique ;
    foreach my $char (@chars) {
        $unique{$char}++;
    }

    return 5    if(scalar keys %unique < 3);

    my $types = 0;
    $types++    if($password =~ /[a-z]/);
    $types++    if($password =~ /[A-Z]/);
    $types++    if($password =~ /\d/);
    $types++    if($password =~ /[^a-zA-Z\d]/);
    return 0    if($types > 1);

    return 3;
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item UserSelect

Provides a dropdown selection box, as a XHTML code snippet, of the currently 
listed users.

By default only users listed as searchable are listed.

=back

=cut

sub UserSelect {
    my $opt   = shift;
    my $multi = shift || 5;
    my $blank = shift || 0;
    my $field = shift || 'userid';
    my $title = shift || 'Name';
    my $all   = shift;
    my $search;

    $search = 'WHERE search=1'   unless($all);

    my @rows = $dbi->GetQuery('hash','AllUsers',{search=>$search});
    foreach (@rows) { 
        my @names;
        push @names, $_->{realname}             if($_->{realname});
        push @names, '(' . $_->{nickname} . ')' if($_->{nickname});
        $_->{name}   = join(' ',@names)   if(@names);
        $_->{name} ||= 'No Name Given';
    }
    unshift @rows, {userid=>0,name=>"Select $title"}    if($blank == 1);
    return DropDownMultiRows($opt,$field,'userid','name',$multi,@rows) if($multi > 1);
    return DropDownRows($opt,$field,'userid','name',@rows);
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
