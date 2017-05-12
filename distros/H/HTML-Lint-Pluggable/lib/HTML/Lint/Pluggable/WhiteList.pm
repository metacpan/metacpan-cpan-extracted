package HTML::Lint::Pluggable::WhiteList;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.08';

use Carp qw/croak/;

sub init {
    my($class, $lint, $conf) = @_;

    my $rule = $conf->{rule} or croak 'required option: rule';
    $lint->override(gripe => sub {
        my $super = shift;
        return sub {
            my $self     = shift;
            my $errcode  = shift;
            my %errparms = @_;

            if (my $is_whitelist = $rule->{$errcode}) {
                return if $is_whitelist->(\%errparms);
            }

            $self->$super($errcode, %errparms);
        };
    });
}

1;
__END__

=head1 NAME

HTML::Lint::Pluggable::WhiteList - to ignore certain errors that have been specified

=head1 VERSION

This document describes HTML::Lint::Pluggable::WhiteList version 0.08.

=head1 SYNOPSIS

    use HTML::Lint::Pluggable;

    my $lint = HTML::Lint::Pluggable->new;
    $lint->load_plugin(WhiteList => +{
        rule => +{
            'attr-unknown' => sub {
                my $param = shift;
                if ($param->{tag} =~ /input|textarea/ && $param->{attr} eq 'istyle') {
                    return 1;
                }
                else {
                    return 0;
                }
            },
        },
    });

=head1 AUTHOR

Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Kenta Sato. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
