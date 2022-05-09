package File::Rename::Unicode;

use 5.012;

use strict;
use warnings;

use Encode qw(encode decode);

our $VERSION = '1.30';

sub code {
    my $code = shift;
    my $encoding = shift;
    return
        sub {
            use feature 'unicode_strings';
            if ( $encoding ) {
                $_ = decode($encoding, $_);
            }
            else {
                utf8::upgrade $_;
            }
            $code->();
            if ( $encoding ) {
                $_ = encode($encoding, $_);
            }
        };
}

1;

__END__

=head1 NAME

File::Rename::Unicode - Unicode wrapper for user code for File::Rename

=head1 SYNOPSIS

    require File::Rename::Unicode;
    my $sub = File::Rename::Unicode::code($code, $enc);

=head1 DESCRIPTION

=over 4

=item C<code()>

Wrap the call to user code in utf8/unicode features.

=back

=head2 OPTIONS

See L<rename> script --unicode option 

See L<File::Rename> for unicode_strings option

=head1 ENVIRONMENT

No environment variables are used.

=head1 SEE ALSO

File::Rename(3), rename(1)

=head1 AUTHOR

Robin Barker <RMBarker@cpan.org>

=head1 DIAGNOSTICS

None

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Robin Barker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


