package MPMinus::Transaction; # $Id: Transaction.pm 274 2019-05-09 18:52:43Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MPMinus::Transaction - MVC SKEL Transaction (MST) pattern

=head1 VERSION

Version 1.06

=head1 SYNOPSIS

    my $q = new CGI;
    my ($actObject, $actEvent) = split /[,]/, $q->param('action') || '';
    $actObject = 'default' unless $actObject && $m->ActionCheck($actObject);
    $actEvent = $actEvent && $actEvent =~ /go/ ? 'go' : '';

    $r->content_type( $m->getActionRecord($actObject)->{content_type} );

    my $status = $m->ActionTransaction($actObject,$actEvent);

    my $status = $m->ActionExecute($actObject,'cdeny');

=head1 DESCRIPTION

Working with MVC SKEL Transactions (MST) pattern.

See MVC SKEL Transaction L<MPMinus::Manual>

=head1 METHODS

=over 8

=item B<ActionTransaction>

    my $status = $m->ActionTransaction( $actObject, $actEvent );

Start MVC SKEL Transaction by $actObject and $actEvent

=item B<ActionExecute>

    my $status = $m->ActionExecute( $actObject, $handler_name );

Execute $handler_name action by $actObject.

$handler_name must be: mproc, vform, cchck, caccess, cdeny

=item B<ActionCheck>

    my $status = $m->ActionCheck( $actObject );

Check existing status of $actObject handler

=item B<getActionRecord>

    my $struct = $m->getActionRecord( $actObject );

Returns meta record of $actObject

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<MPMinus>, L<CTK::Util>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<MPMinus>, L<CTK::Util>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = 1.06;

use Carp;
use Apache2::Const;

use constant {
        HOOKS => { # Returned values of hooks / Types of hooks
                caccess => {
                        aliases => [qw/caccess access/],
                        type    => 'DUAL', # BOOL and HTTP way
                    },
                cdeny   => {
                        aliases => [qw/cdeny deny/],
                        type    => 'HTTP', # Analyzing common constants and HTTP 1.1 status codes
                    },
                cchck   => {
                        aliases => [qw/cchck chck check/],
                        type    => 'BOOL', # 0 - false / !0 - true
                    },
                mproc   => {
                        aliases => [qw/mproc proc proccess/],
                        type    => 'HTTP', # Analyzing common constants and HTTP 1.1 status codes
                    },
                vform   => {
                        aliases => [qw/vform form/],
                        type    => 'HTTP', # Analyzing common constants and HTTP 1.1 status codes
                    },
            },
    };

sub ActionTransaction { # Returns status - 0 or HTTP_* codes
    my $m = shift || '';
    my $key = shift || return 0;
    my $event = shift || '';
    croak("The method call is made ActionTransaction not in the style of MPMinus") unless ref($m) =~ /MPMinus/;

    my $sts = 0;

    # Access action (false - deny; true - allow)
    $sts = ActionExecute($m,$key,'caccess');

    # Oops! No access!
    unless ($sts) {
        # Call cdeny
        $sts = ActionExecute($m,$key,'cdeny');
        return $sts;
    }
    return $sts if $sts >= 300; # Returns HTTP_* if code >= 300 (data from caccess)

    # Run process (mproc) if $event defined and cchck returns valid value
    $sts = ActionExecute($m,$key,'mproc') if (($event =~ /go/i) && ActionExecute($m,$key,'cchck'));
    return $sts if $sts >= 300; # Returns HTTP_* if code >= 300 (data from mproc)

    # Show form
    $sts = ActionExecute($m,$key,'vform');
    return $sts;
}
sub ActionExecute {
    # Run one or more handlers until first negative (false) return code
    my $m = shift || '';
    my $key = shift || return 0;
    my $hook = shift || return 0;
    my @params = @_;
    croak("The method call is made ActionExecute not in the style of MPMinus") unless ref($m) =~ /MPMinus/;

    return 0 unless ActionCheck($m,$key); # Return if key is not found
    my %hooks = %{(HOOKS)};
    return 0 unless grep {$_ eq $hook} keys %hooks; # Return 0 if context is not defined (default)

    # Get handler
    my $grec = $m->drec;
    my $rec = $grec->{actions}{$key}{handler};
    my $phase = _getPhaseByAlias($rec,$hook);

    if (ref($phase) eq 'CODE') {
        # Run code
        return $phase->($m,@params)
    } elsif (ref($phase) eq 'ARRAY') {
        my $status;
        foreach (@$phase) {
            $status = (ref($_) eq 'CODE') ? $_->($m,@params) : 0;
            my $typ = $hooks{$hook}{type};

            if ($typ eq 'BOOL') {
                last unless $status; # Return if false
            } elsif ($typ eq 'HTTP') {
                # Return if >=300 (REDIRECTIONS AND ERRORS)
                last unless (($status =~ /^[+\-]?\d+$/) && $status < 300);
            } elsif ($typ eq 'DUAL') {
                # Return if 0 (OK) or >=300 (REDIRECTIONS AND ERRORS)
                last unless $status; # Return if false
                last unless (($status =~ /^[+\-]?\d+$/) && $status < 300);
            } else { # VOID and etc.
                $status = Apache2::Const::OK;
            }
        }
        return $status;
    } else {
        return 0;
    }
    return 0;
}
sub ActionCheck {
    my $m = shift || '';
    my $key = shift || return 0;
    croak("The method call is made ActionCheck not in the style of MPMinus") unless ref($m) =~ /MPMinus/;
    return $m->drec->{actions}{$key} ? 1 : 0;
}
sub getActionRecord {
    my $m = shift || '';
    my $key = shift;
    croak("The method call is made getActionRecord not in the style of MPMinus") unless ref($m) =~ /MPMinus/;
    my $grec = $m->drec;
    if ($key) {
        return $grec->{actions}{$key} ? $grec->{actions}{$key} : undef;
    }
    return $grec->{actions};
}

sub _getPhaseByAlias {
    my $rec = shift || {};
    my $hook = shift || '_';
    my %hooks = %{(HOOKS)};
    my $aliases = $hooks{$hook}{aliases};

    my $ret;
    foreach (@$aliases) {
        if ($rec->{$_} && ref($rec->{$_})) {
            $ret = $rec->{$_};
            last;
        }
    }

    return $ret;
}

1;
