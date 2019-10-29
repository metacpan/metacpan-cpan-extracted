package Log::Any::Plugin::Encode;
# ABSTRACT: Output message encoding for log adapters
$Log::Any::Plugin::Encode::VERSION = '0.010';
use strict;
use warnings;

use Carp qw( croak );

use Encode qw( find_encoding );

use Log::Any::Plugin::Util qw( get_old_method set_new_method );


sub install {
    my ($class, $adapter_class, %args) = @_;

    my $encoding = $args{encoding} || 'utf8';
    my $encoder = find_encoding($encoding) or
        croak "Could not find encoder for encoding[$encoding], check encoding value for typos, or codec installed";

    for my $method_name ( Log::Any->logging_methods() ) {
        my $old_method = get_old_method($adapter_class, $method_name);

        set_new_method($adapter_class, $method_name, sub {
            my $self = shift;

            my @encoded_msgs = map { $encoder->encode($_, Encode::FB_WARN) } @_;

            return $self->$old_method(@encoded_msgs);
        });
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Plugin::Encode - Output message encoding for log adapters

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    # Set up some kind of logger.
    use Log::Any::Adapter;
    Log::Any::Adapter->set('SomeAdapter');

    # Apply the Levels plugin to your logger
    use Log::Any::Plugin;
    Log::Any::Plugin->add('Encode', encoding => 'utf8'); # utf8 is default if not specified


    # In your modules
    use Log::Any qw($log);

    $log->error('error'); # output is <encoding> encoded, in this case UTF-8

    # Applies to every log method.

=head1 DESCRIPTION

This came about from noticing warnings of wide chars being output to adapter
streams. This plugin may be inserted as needed to explicitly transform
log messages into the configured encoding.

=head1 CONFIGURATION

Configuration values are passed as key-value pairs when adding the plugin:

    Log::Any::Plugin->add('Encode', encoding => 'utf8');

This implementation relies on the L<Encode> module to perform encoding, refer
to that for supported encodings.

=head2 encoding => $encoding

Defaults to 'utf8' if not specified. An unknown encoding will throw an error.

=head1 METHODS

There are no methods in this package which should be directly called by the
user. Use Log::Any::Plugin->add() instead.

=head2 install

Private method called by Log::Any::Plugin->add()

=head1 ACKNOWLEDGEMENTS

Thanks to Strategic Data for sponsoring the development of this module.

=head1 AUTHOR

Stephen Thirlwall <sdt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2011 by Stephen Thirlwall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
