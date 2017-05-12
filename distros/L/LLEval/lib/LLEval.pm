package LLEval;
use 5.008_001;
use Mouse;
use MouseX::StrictConstructor;
use JSON;
use Furl;
use URI::Escape qw(uri_escape_utf8);

our $VERSION = '0.01';

has api_host => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'api.dan.co.jp',
);

has api_pathq_base => (
    is       => 'ro',
    isa      => 'Str',
    default  => '/lleval.cgi',
);

has _furl => (
    is       => 'ro',
    isa      => 'Object',
    default  => sub {
        return Furl->new( agent => "LLEval-Client/$VERSION" ),
    },
);

has _json => (
    is       => 'ro',
    isa      => 'Object',
    default  => sub {
        return JSON->new->utf8->pretty;
    },
);

sub call {
    my($self, %args) = @_;

    my $path_query = $self->api_pathq_base . '?';
    while(my($key, $value) = each %args) {
        next unless defined $value;
        $path_query .= sprintf '&%s=%s',
            uri_escape_utf8($key), uri_escape_utf8($value);
    }
    #warn $path_query;
    my $res = $self->_furl->request(
        host       => $self->api_host,
        path_query => $path_query,
    );
    if($res->code != 200) {
        confess "API Error: ", $res->status_line;
    }
    return $self->_json->decode($res->content);
}

sub call_eval {
    my($self, $source, $lang) = @_;
    return $self->call( s => $source, l => $lang );
}

sub eval {
    my($self, $source, $lang, $stdout_to, $stderr_to) = @_;
    my $data = $self->call_eval($source, $lang);

    if(defined $stdout_to) {
        ${$stdout_to} = $data->{stdout};
    }
    else {
        print $data->{stdout};
    }
    if(defined $stderr_to) {
        ${$stderr_to} = $data->{stderr};
    }
    else {
        Carp::carp($data->{stderr});
    }
    return $data->{status};
}

# list of supported languages
sub languages {
    my($self) = @_;
    my $data = $self->call(q => 1);
    delete $data->{error};
    return $data;
}

sub pretty {
    my($self, $data) = @_;
    return $self->_json->encode($data);
}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

LLEval - Perl interface to dankogai's LLEval service

=head1 VERSION

This document describes LLEval version 0.01.

=head1 SYNOPSIS

    In fuzzbuzz.p6:
    #!lleval
    # This is a Perl6 script
    [1..30].map({
      { $^n % 3 ?? '' !! 'Fizz' }($_)
      ~
      { $^n % 5 ?? '' !! 'Buzz' }($_)
      || $_
    }).join("\n").say;

    Or from the shell:
    lleval -x hs 'main = putStrLn "Hello, Haskell world!"'

=head1 DESCRIPTION

This is a Perl interface to dankogai's LLEval service.

=head1 INTERFACE

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<http://colabv6.dan.co.jp/lleval.html>

=head1 AUTHOR

gfx E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, gfx. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
