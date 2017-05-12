package HTTP::Request::AsCurl;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.03";

use Carp;
use String::ShellQuote qw/ shell_quote /;
use Win32::ShellQuote qw/ cmd_escape /;
use Exporter::Shiny qw/ as_curl /;

sub as_curl {
    my ($request, %params) = @_;

    my $content = $request->content;
    my @data    = split '&', $content;
    my $method  = $request->method;
    my $uri     = $request->uri;
    my $headers = $request->headers;
    my $user    = $headers->authorization_basic;
    my @h       = grep { $_ !~ /(authorization|content-length|content-type)/i }
        $headers->header_field_names;

    my @cmd = (["curl"]);
    push(@cmd, ["--request", $method, $uri]);
    push(@cmd, ["--dump-header", "-"]);
    push(@cmd, ["--user",   $user]) if $user;
    push(@cmd, ["--header", "$_: " . $headers->header($_)]) for sort @h;
    push(@cmd, ["--data", $_]) for sort @data;

    return map { @$_ } @cmd unless keys %params;

    return _make_it_pretty(\@cmd, %params);
}

sub _make_it_pretty {
    my ($cmd, %params) = @_;

    $params{shell}   = $params{shell}   || _default_shell_escape();
    $params{newline} = $params{newline} || "\n";

    my $string;
    for my $part (@$cmd) {
        if ($params{shell} eq 'win32') {
            $string .= cmd_escape join " ", @$part;
            $string .= ' ^' . $params{newline};
        }
        elsif ($params{shell} eq 'bourne') {
            $string .= shell_quote @$part;
            $string .= ' \\' . $params{newline};
        }
        else {
            croak "this shell is not currently supported: $params{shell}";
        }

    }

    return $string;
}

sub _default_shell_escape { $^O eq 'MSWin32' ? 'win32' : 'bourne' }


1;
__END__

=encoding utf-8

=head1 NAME

HTTP::Request::AsCurl - Generate a curl command from an HTTP::Request object.


=head1 SYNOPSIS

    use HTTP::Request::Common;
    use HTTP::Request::AsCurl qw/as_curl/;

    my $request = POST('api.earth.defense/weapon1', { 
        target => 'mothership', 
        when   => 'now' 
    });

    system as_curl($request);

    print as_curl($request, pretty => 1, newline => "\n", shell => 'bourne');
    # curl \
    # --request POST api.earth.defense/weapon1 \
    # --dump-header - \
    # --data target=mothership \
    # --data when=now


=head1 DESCRIPTION

This module converts an HTTP::Request object to a curl command.  It can be used
for debugging REST APIs. 

It handles headers and basic authentication.


=head1 METHODS

=head2 as_curl($request, %params)

Accepts an HTTP::Request object and converts it to a curl command.  If there
are no C<%params>, C<as_curl()> returns the cmd as an array suitable for being
passed to system().  

If there are C<%params>, C<as_curl()> returns a formatted string.  The string's
format defaults to using "\n" for newlines and escaping the curl command using
bourne shell rules unless you are on a win32 system in which case it defaults
to using win32 cmd.exe escaping rules.

Available params are as follows

    newline: defaults to "\n"
    shell:   currently available options are 'bourne' and 'win32'


=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

