package Kwiki::ModPerl;
use Kwiki -Base;
our $VERSION = "0.09";

BEGIN {
    eval { require mod_perl2 } || require mod_perl;
    if ( $mod_perl::VERSION >= 1.999021 ) {
        require Apache2::RequestRec;
        require Apache2::RequestUtil;
        require Apache2::RequestIO;
        require Apache2::Const;
        Apache2::Const->import qw(:common);
    } else {
        if ( $mod_perl::VERSION >= 1.99 ) {
            require Apache::RequestRec;
            require Apache::RequestUtil;
            require Apache::RequestIO;
            require Apache::Const;
            Apache::Const->import qw(:common);
        } else {
            require Apache;
            require Apache::Constants;
            Apache::Constants->import( qw/:response :common/);
        }
    }
}

use constant MP2 => $mod_perl::VERSION >= 1.99 ? 1 : 0;

sub handler_mp1 ($$)     { &run }
sub handler_mp2 : method { &run }

*handler = MP2 ? \&handler_mp2 : \&handler_mp1;

sub get_new_hub {
    my $path = shift;
    chdir $path;
    my $hub = $self->new->debug->load_hub(
        "config*.*", -plugins => "plugins",
    );
    return $hub;
}

sub run {
    my $r = shift;

    # only handle the directory specified in the apache config.
    # return declined to let Apache serve regular files.
    my $path = $r->dir_config('KwikiBaseDir');
    # People might put trailing slashes in their configuration
    $path =~ s/\/+$//;

    # modperl 2 gives trailing slash
    my $rpath = $r->filename;
    $rpath =~ s/(\/index.cgi)?\/?$//;

    # CoolURI Handling
    my $ret = $self->coolURI_handler($r, $rpath, $path);
    $rpath = $ret if $ret;

    # Support sub-view. sub_view = sub-dir with the "registry.dd" file.
    $path = $rpath if(io->catfile($rpath,"registry.dd")->exists);

    return DECLINED unless $rpath eq $path;
    my $hub = $self->get_new_hub($path);

    eval { $hub->pre_process }
        or $self->print_error($@,$r,$hub,'Pre-Process Error');

    my $html = eval { $hub->process };
    return $self->print_error($@,$r,$hub,'Process Error') if $@;

    if (defined $html) {
        $hub->headers->print;
        unless($r->header_only) {
            $self->utf8_encode($html);
            $r->print($html);
        }
    }
    eval { $hub->post_process }
        or $self->print_error($@,$r,$hub,'Post-Process Error');

    return ($hub->headers->redirect)?REDIRECT:OK;
}

sub print_error {
    my $error = $self->html_escape(shift);
    my ($r,$hub,$msg) = @_;
    $hub->headers->content_type('text/html');
    $hub->headers->charset('UTF-8');
    $hub->headers->expires('now');
    $hub->headers->pragma('no-cache');
    $hub->headers->cache_control('no-cache');
    $hub->headers->redirect('');
    $hub->headers->print;
    $r->print("<h1>Software Error:</h1><h2>$msg</h2><pre>\n$error</pre>");
    return OK;
}

sub coolURI_handler {
    my ($r, $rpath, $path) = @_;

    # if its a real file, show it 
    return undef if (-f $rpath or -l $rpath);
    # if it's a dir, it should be a sub-view
    return undef if -d $rpath;

    # If we have args, we are doing something else.
    return $path if ($r->args and $r->args =~ /\w+/);

    # Okay, now lets do some CoolURI stuff
    my $pagename = $rpath;
    $pagename =~ s|^$path||;

    if ($pagename =~ /\w+/) {
        $pagename =~ s{/+}{}g;
        my $query_string = "action=display&page_name=$pagename";
        $r->subprocess_env(QUERY_STRING=>$query_string);
        $ENV{QUERY_STRING} = $query_string;
        $r->path_info('');
        $r->args($query_string);
        $rpath =~ s|$pagename$||;
        return $path;
    }
    return undef;
}

__END__

=head1 NAME

Kwiki::ModPerl - enable Kwiki to work under mod_perl

=head1 SYNOPSIS

 $ kwiki -new /path/to/webroot/kwiki

In your Apache configuration:

 <Location /kwiki>
   SetHandler  perl-script
   PerlSetVar  KwikiBaseDir /path/to/webroot/kwiki
   PerlHandler +Kwiki::ModPerl
 </Location>

If you have a custom F<lib> directory for your Kwiki:

 <Perl>
   use lib '/path/to/webroot/kwiki/lib';
 </Perl>

Also if you're using mod_perl2, please add the following line
into your httpd.conf:

  PerlModule Apache2

=head1 DESCRIPTION

This module allows you to use Kwiki as a mod_perl content handler.

=head1 FEATURES, BUGS and NOTES

=over 4

=item * B<Sub-view are supported automatically>

No extra apache configuration is required.

=item * B<Multiple Kwikis are supported.>

As long as each Kwiki has its own KwikiBaseDir, you're golden.

=item * B<You might need a redirect for the Kwiki base directory.>

For example, if your Kwiki is at the location C</kwiki/> and you
browse to C</kwiki> (without the trailing slash), you'll definitely
experience some weirdness.  I highly suggest adding a redirect:

    RedirectMatch ^/kwiki$ http://example.com/kwiki/

=item * B<Why index.cgi still shows up in the URL ?>

Don't worry, it's ignored internally, so that it is still handled
under mod_perl, not as a cgi script. Also, It can make all browser
happy with relative URI redirection. (Although it shouldn't be a
relative redirection, should be fixed in Kwiki base in the future).

=item * B<You might need to restart Apache.>

Otherwise module additions and removal might not be working.

=back

=head1 AUTHORS

Ian Langworth <langworth.com>

Now Maintained by Kang-min Liu <gugod@gugod.org>

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth
Copyright (C) 2005 by Kang-min Liu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

