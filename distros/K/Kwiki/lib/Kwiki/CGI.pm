package Kwiki::CGI;
use Spoon::CGI -Base;
use Kwiki ':char_classes';

sub init {
    $self->add_params('page_name');
}

cgi 'action';
cgi 'button';

sub page_name {
    return $self->{page_name} = shift if @_;
    return $self->{page_name}
      if defined $self->{page_name};
    my $page_name = CGI::param('page_name');
    if (not defined $page_name) {
        my $query_string = CGI::query_string();
        $query_string =~ s/%([0-9a-fA-F]{2})/pack("H*", $1)/ge;
        if ($query_string =~ /^keywords=/) {
            $page_name = join ' ',
                            grep length($_),
                            split /;?keywords=/, $query_string;
        }
        elsif ($ENV{QUERY_STRING} and $ENV{QUERY_STRING} =~ /[^=&;]+[&;]/) {
            ($page_name = $ENV{QUERY_STRING}) =~ s/(.*?)[&;].*/$1/;
        }
    }
    $page_name = '' if defined $page_name && $page_name =~ /=/;
    $page_name = $self->uri_unescape($page_name);
    $self->{page_name} = $self->set_default_page_name($page_name);
}

sub set_default_page_name {
    my $page_name = shift;
    $page_name = '' if $page_name and $page_name =~ /[^$ALPHANUM]/;
    $page_name ||= $self->hub->config->main_page;
}

__DATA__

=head1 NAME 

Kwiki::CGI - Kwiki CGI Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
