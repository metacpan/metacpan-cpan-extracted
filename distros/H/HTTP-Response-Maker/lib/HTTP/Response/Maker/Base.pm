package HTTP::Response::Maker::Base;
use strict;
use warnings;
use HTTP::Status qw(:constants status_message);
use Sub::Name;

sub import {
    my ($class, %args) = @_;
    my $pkg = caller;

    my $prefix          = delete $args{prefix} || '';
    my $default_headers = delete $args{default_headers};
    foreach my $constant (@HTTP::Status::EXPORT) {
        (my $name = $constant) =~ s/^RC_/$prefix/ or next;
        no strict 'refs';
        *{"$pkg\::$name"} = subname "$pkg\::$name"
            => $class->_make_response_function(&{"HTTP::Status::$constant"}, $default_headers, \%args);
    }
}

sub _make_response_function {
    my ($class, $code, $default_headers, $import_option) = @_;

    return sub {
        my @args = $class->_expand_args($code, $default_headers, @_);
        return $class->_make_response(@args, $import_option);
    };
}

sub _expand_args {
    my $class           = shift;
    my $code            = shift;
    my $default_headers = shift || do {
        require HTTP::Response::Maker;
        \@HTTP::Response::Maker::DefaultHeaders;
    };

    my $headers = ref $_[0] eq 'ARRAY' ? shift : [ @$default_headers ];
    my $content = shift;
    my $message = status_message($code);

    $content = "$code $message" if not defined $content;
    $content = '' if $code == HTTP_NO_CONTENT || $code == HTTP_NOT_MODIFIED;

    return ( $code, $message, $headers, $content );
}

1;

__END__

=head1 NAME

HTTP::Response::Maker::Base - base class for HTTP::Response::Maker::*

=cut
