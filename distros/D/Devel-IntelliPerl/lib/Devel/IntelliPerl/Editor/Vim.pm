package Devel::IntelliPerl::Editor::Vim;
our $VERSION = '0.04';

use Moose;

use Exporter qw(import);
use Devel::IntelliPerl;

extends 'Devel::IntelliPerl::Editor';

our @EXPORT = qw(run);

has editor => ( isa => 'Str', is => 'ro', default => 'Vim' );

sub run {
    my ($self) = @_;
    my @source;
    my ( $line_number, $column, $filename ) = @ARGV;
    push( @source, $_ ) while (<STDIN>);
    my $ip = Devel::IntelliPerl->new(
        line_number => $line_number,
        column      => $column + 1,
        source      => join( '', @source ),
        filename    => $filename
    );
    print length( $ip->prefix ), "\n";

    my @methods = $ip->methods;
    if ( @methods > 1 ) {
        print join( "\n", @methods );
    }
    elsif ( my $method = shift @methods ) {
        print $method;
    }
    elsif ( my $error = $ip->error ) {
        print "The following error occured:\n" . $error;
    }

}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Devel::IntelliPerl::Editor::Vim - IntelliPerl integration for Vim 

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    package Test;
    use Moose;

    has a_varaible => ( is => 'rw', isa => 'Str' );

    sub a_method {
        my $self = shift;
        $self->a^^;
    }


Pressing <c-x><c-o> from insert mode in Vim will offer up a menu to
auto complete with either C<a_method> or C<a_varaible>.

=head1 DESCRIPTION

Vim uses the omnifunction to autocomplete most languages. This is typically
mapped to C<< <c-x><c-o> >> which is vim speak for (ctrl-x followed by crtl-o).
Add the following to your C<~/.vim/ftplugin/perl.vim> file and the 
omnifunction should run L<Devel::IntelliPerl> for perl method completion.

    setlocal omnifunc=Ocf_devel_intelliperl
    function! Ocf_devel_intelliperl(findstart, base)
    " This function is called twice, once with a:findstart and immediately
    " thereafter without a:findstart
    " With a:findstart, return the col where the prefix starts
    " Without a:findstart, return the method options
    " We run Devel::IntelliPerl only once and cache the results
    if a:findstart

    " Get some info for the command
    let line = line('.')
    let column = col('.') - 1
    let filename = expand("%")

    " Defined the Devel::IntelliPerl command
    let command = "perl -MDevel::IntelliPerl::Editor::Vim -e 'run' " . line . ' ' . column . ' ' . filename

    " Get the current contents of the buffer (we don't want to have to write the file)
    let buffer_contents = join( getline(1,"$"), "\n" )

    " Run the command and munge the results into a list
    let result_str = system(command, buffer_contents )
    let s:ofc_results = split( result_str, " *\n" )
    let prefix_len = s:ofc_results[0]

    return col('.') - prefix_len - 1
    endif

    return s:ofc_results[1:-1]
    endfunction

=head1 METHODS

=head2 editor

Set to C<Vim>.

=head2 run

This method is exported and invokes L<Devel::IntelliPerl>.

=head1 SEE ALSO

L<Devel::IntelliSense>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mark Grimes, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut