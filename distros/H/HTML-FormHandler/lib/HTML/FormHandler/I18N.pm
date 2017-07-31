package HTML::FormHandler::I18N;
# ABSTRACT: internationalization
$HTML::FormHandler::I18N::VERSION = '0.40068';
use strict;
use warnings;
use base ('Locale::Maketext');
use Try::Tiny;

sub maketext {
    my ( $lh, @message ) = @_;
    return '' unless scalar @message;
    return '' unless defined $message[0];
    my $out;
    try {
        $out = $lh->SUPER::maketext(@message);
    }
    catch {
        die "Unable to do maketext on: " . $message[0] .
            "\nIf the message contains brackets you may need to escape them with a tilde.";
    };
    return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::I18N - internationalization

=head1 VERSION

version 0.40068

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
