package L;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp ();
use Module::Load ();

{
    package
        UNIVERSAL;

    our $AUTOLOAD;
    sub AUTOLOAD {
        return if $AUTOLOAD =~ /::DESTROY$/;
        if (my ($module, $method) = ($AUTOLOAD =~ /^(.*)::(.*?)$/)) {
            if ($module eq 'main') {
                Carp::croak(qq{Undefined subroutine &main::$method called});
            }

            Module::Load::load($module);

            my $func = $module->can($method)
                or Carp::croak qq{Can't locate object method "$method" via package "$module"};

            $func->(@_);
        } else {
            die "WTF? $AUTOLOAD";
        }
    }
}

1;
__END__

=head1 NAME

L - Perl extention to load module automatically in one liner.

=head1 VERSION

This document describes L version 0.01.

=head1 SYNOPSIS

    % perl -ML -E 'say String::Random->new->randregex("[0-9a-zA-Z]{12}")'

=head1 DESCRIPTION

Module auto loader for one liner.

This modules is dangerous, then don't use this module in other perl modules, scripts or product code.
This should be used only in one liner.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 CONTRIBUTORS

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

(Most of code is written by him.)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Masayuki Matsuki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
