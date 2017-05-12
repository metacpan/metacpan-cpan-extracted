package Hubot::Scripts::roles;
$Hubot::Scripts::roles::VERSION = '0.2.8';
use strict;
use warnings;

sub load {
    my ( $class, $robot ) = @_;
    $robot->respond(
        qr/who is \@?([\w \.-_]+)\?*$/i,
        sub {
            my $msg    = shift;
            my $joiner = ', ';
            my $name   = $msg->match->[0];
            $name =~ s/(^\s+|\s+$)//g;

            if ( $name eq 'you' ) {
                $msg->send("Who ain't I?");
            }
            elsif ( $name eq $robot->name ) {
                $msg->send("The best.");
            }
            else {
                my @users = $robot->usersForFuzzyName($name);
                if ( scalar @users == 1 ) {
                    my $user = $users[0];
                    $user->{roles} ||= [];
                    my @roles = @{ $user->{roles} };
                    if ( scalar @roles > 0 ) {
                        $joiner = '; ' if join( '', @roles ) =~ m/,/;
                        $msg->send( "$name is " . join( $joiner, @roles ) );
                    }
                    else {
                        $msg->send("$name is nothing to me.");
                    }
                }
                elsif ( scalar @users > 1 ) {
                    $msg->send( getAmbiguousUserText(@users) );
                }
                else {
                    $msg->send("$name? Never heard of 'em");
                }
            }
        }
    );

    $robot->respond(
        qr/\@?([\w \.-_]+) is ([\"\'\w: -_]+)[\.!]*$/i,
        sub {
            my $msg = shift;
            my ( $name, $newRole ) = @{ $msg->match };
            $name =~ s/(^\s+|\s+$)//g;
            $newRole =~ s/(^\s+|\s+$)//g;
            if ( $name !~ m/^(|who|what|where|when|why)$/i ) {
                unless ( $newRole =~ m/^not\s+/i ) {
                    my @users = $robot->usersForFuzzyName($name);
                    if ( scalar @users == 1 ) {
                        my $user = $users[0];
                        $user->{roles} ||= [];
                        if ( grep { $newRole eq $_ } @{ $user->{roles} } ) {
                            $msg->send("I know.");
                        }
                        else {
                            push @{ $user->{roles} }, $newRole;
                            if ( lc $name eq $robot->name ) {
                                $msg->send("OK, I am $newRole.");
                            }
                            else {
                                $msg->send("OK, $name is $newRole.");
                            }
                        }
                    }
                    elsif ( scalar @users > 1 ) {
                        $msg->send( getAmbiguousUserText(@users) );
                    }
                    else {
                        $msg->send("I don't know anything about $name.");
                    }
                }
            }
        }
    );

    $robot->respond(
        qr/\@?([\w \.-_]+) is not ([\"\'\w: -_]+)[\.!]*$/i,
        sub {
            my $msg = shift;
            my ( $name, $newRole ) = @{ $msg->match };
            $name =~ s/(^\s+|\s+$)//g;
            $newRole =~ s/(^\s+|\s+$)//g;
            if ( $name !~ m/^(|who|what|where|when|why)$/i ) {
                my @users = $robot->usersForFuzzyName($name);
                if ( scalar @users == 1 ) {
                    my $user = $users[0];
                    $user->{roles} ||= [];
                    if ( !grep { $newRole eq $_ } @{ $user->{roles} } ) {
                        $msg->send("I know.");
                    }
                    else {
                        my @roles
                            = grep { $newRole ne $_ } @{ $user->{roles} };
                        $user->{roles} = \@roles;
                        $msg->send("OK, $name is no longer $newRole.");
                    }
                }
                elsif ( scalar @users > 1 ) {
                    $msg->send( getAmbiguousUserText(@users) );
                }
                else {
                    $msg->send("I don't know anything about $name.");
                }
            }
        }
    );
}

sub getAmbiguousUserText {
    my @users = @_;
    return sprintf(
        "Be more specific, I know %d people named like that: %s",
        scalar @users,
        join( ', ', map { $_->{name} } @users )
    );
}

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Scripts::roles

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    hubot <user> is a badass guitarist - assign a role to a user
    hubot <user> is not a badass guitarist - remove a role from a user
    hubot who is <user> - see what roles a user has

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
