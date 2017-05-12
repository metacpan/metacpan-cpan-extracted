package Maypole::Cache;
use Maypole::Constants;
use Class::ISA;

use 5.00005;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw( handler_guts );

$VERSION = '1.2';

sub handler_guts {
    my $r = shift;
    my %options = %{$r->{config}{cache_options} || {}};
    my $cache_class = delete($options{class})
                    || "Cache::SharedMemoryCache";
    $options{namespace} ||= ref($r);
    $options{default_expires_in} ||= 600;
    if (!$cache_class->require) {
        warn "COULDN'T USE CACHE!: $@";
        bail:
            # We have to fake SUPER because of the way Perl works.
            my ($class) = grep { UNIVERSAL::can($_, "handler_guts") }
                Class::ISA::super_path(ref $r);
            no strict "refs";
            return $class->can("handler_guts")->($r);   
    } 

    # Don't cache POST requests.
    do { warn "POST detected"; goto bail} if keys %{$r->{params}};

    no warnings 'uninitialized';
    my $key = "$r->{user}:$r->{path}";
    $key .= ":".$_."/".$r->{query}{$_} for sort keys %{$r->{query}||{}};
    my $cache = $cache_class->new(\%options);

    # Now we're really into the handler guts proper...

    $r->model_class($r->config->{model}->class_of($r, $r->{table}));
    if ($r->is_applicable == OK) {
        # Don't cache auth failures
        my $status = $r->authenticate;
        return $status unless $status == OK;

        $r->additional_data();
        # Do the cache
        return OK if $r->{output} = $cache->get($key);
        $r->model_class->process($r);
    } else {       
        return OK if $r->{output} = $cache->get($key);
        delete $r->{model_class};
        $r->{path} =~ s{^/}{}; # De-absolutify
        $r->template($r->{path});
    }
    if ($r->{output}) {
        $cache->set($key, $r->{output}) unless $r->{nocache};
        return OK;
    } else {
        my $status = $r->view_object->process($r);
        $cache->set($key, $r->{output}) if $status == OK and ! $r->{nocache};
        return $status;
    }
}



# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Maypole::Cache - Flexible caching of Maypole request output

=head1 SYNOPSIS

  package BeerDB;
  use base 'Apache::MVC';
  use Maypole::Cache;
  BeerDB->config->{cache_options} = {
    class => "Cache::FileCache",
    default_expires_in => 600,
    ...
  };

=head1 DESCRIPTION

This module replaces Maypole's main handler in your application with
one which uses C<Cache::Cache> to cache request output. By default it
uses C<Cache::SharedMemoryCache> although this, and all other
C<Cache::Cache> options, can be changed using the C<cache_options>
configuration hash.

The module caches all pages, except those which trigger an
authentication failure, or which use POST parameters, or when the
C<nocache> slot in the request object is set to a true value. A separate
cache is maintained for each C<$r-E<gt>user>. You may want certain of
your actions to set C<nocache> if they do anything session-conditional.

=head1 SEE ALSO

L<Maypole>, L<Cache::Cache>

=head1 AUTHOR

Simon Cozens, E<lt>simon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
