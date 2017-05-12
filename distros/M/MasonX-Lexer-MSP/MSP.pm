package MasonX::Lexer::MSP;

# Written by John Williams.  Most code is plagurized from Lexer.pm, which is:
# Copyright (c) 1998-2004 by Jonathan Swartz. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use warnings;
our $VERSION = '0.11';
use base qw(HTML::Mason::Lexer);

use HTML::Mason::Exceptions( abbr => [qw(param_error syntax_error error)] );

use Params::Validate qw(:all);
Params::Validate::validation_options( on_fail => sub { param_error join '', @_ } );


__PACKAGE__->valid_params (
	perl_lines	=> { parse => 'boolean', type => BOOLEAN, default => 0,
				descr => "Allow perl-lines to be used", },
	);


sub start
{
    my $self = shift;

    my $end;
    while ( defined $self->{current}{pos} ?
	    $self->{current}{pos} < length $self->{current}{comp_source} :
	    1 )
    {
	last if $end = $self->match_end;

	$self->match_block && next;

	$self->match_named_block && next;

	$self->match_substitute && next;

	$self->match_code_tag && next;

	$self->match_comment_tag && next;

	$self->match_comp_call && next;

	$self->match_perl_line && next;

	$self->match_comp_content_call && next;

	$self->match_comp_content_call_end && next;

	$self->match_text && next;

	if ( ( $self->{current}{in_def} || $self->{current}{in_method} ) &&
	     $self->{current}{comp_source} =~ /\G\z/ )
	{
	    my $type = $self->{current}{in_def} ? 'def' : 'method';
	    $self->throw_syntax_error("Missing closing </%$type> tag");
	}

	# We should never get here - if we do, we're in an infinite loop.
	$self->throw_syntax_error("Infinite parsing loop encountered - Lexer bug?");
    }

    if ( $self->{current}{in_def} || $self->{current}{in_method} )
    {
	my $type = $self->{current}{in_def} ? 'def' : 'method';
	unless ( $end =~ m,</%\Q$type\E>\n?,i )
	{
	    my $block_name = $self->{current}{"in_$type"};
	    $self->throw_syntax_error("No </%$type> tag for <%$type $block_name> block");
	}
    }
}


sub match_substitute
{
    my $self = shift;

    if ( $self->{current}{comp_source} =~ /\G<%=/gcs )
    {
	if ( $self->{current}{comp_source} =~ /\G(.+?)(\s*\|\s*([\w\s,]+)?\s*)?%>/igcs )
	{
	    my ($sub, $escape) = ($1, $3);
	    $self->{current}{compiler}->substitution( substitution => $sub,
						      escape => $escape );

	    # Add it in just to count lines
	    $sub .= $2 if $2;
	    $self->{current}{lines} += $sub =~ tr/\n/\n/;

	    return 1;
	}
	else
	{
	    $self->throw_syntax_error("'<%=' without matching '%>'");
	}
    }
}

# match <% code %>
# '<%' should not be immediately followed by '=', '|', '&', or '-'
# '=' is substitution, '-' is comments,
# '|' and '&' might be used for components calls in the future
# Actually a space is preferred: i.e. '<% '
sub match_code_tag
{
    my $self = shift;

    if ( $self->{current}{comp_source} =~ /\G<%(?![=|&-])/gcs )
    {
	if ( $self->{current}{comp_source} =~ /\G(.+?)%>/gcs )
	{
	    my $code = $1;
	    $self->{current}{compiler}->raw_block( block_type => 'perl',
						   block => $code );

	    # count lines
	    $self->{current}{lines} += $code =~ tr/\n/\n/;

	    return 1;
	}
	else
	{
	    $self->throw_syntax_error("'<%' without matching '%>'");
	}
    }
}

sub match_comment_tag
{
	my $self = shift;

	if ( $self->{current}{comp_source} =~ /\G<%--/gcs )
	{
		if ( $self->{current}{comp_source} =~ /\G(.*?)--%>/gcs )
		{
			my $comment = $1;
			$self->{current}{compiler}->doc_block( block_type => 'doc',
							block => $comment );

			$self->{current}{lines} += $comment =~ tr/\n/\n/;

			return 1;
		}
		else
		{
			$self->throw_syntax_error("'<%--' without matching '--%>'");
		}
	}
}


sub match_perl_line
{
    my $self = shift;

    return 0 unless $self->{perl_lines};

    return $self->SUPER::match_perl_line(@_);
}


1;

__END__

=head1 NAME

MasonX::Lexer::MSP - Give Mason a more ASP/JSP compatible syntax

=head1 SYNOPSIS

    my $interp = HTML::Mason::Interp->new( 
                 data_dir => '/here',
                 comp_root => '/there',
                 lexer_class => 'MasonX::Lexer::MSP',
                 );

=head1 DESCRIPTION

This lexer makes changes to the Mason syntax to make it closer
to the syntax used by ASP and JSP.  These changes are incompatible
with the default Mason syntax, unfortunately.

=head1 Syntax Changes

The in-line code tag used by ASP and JSP is this: (which conflicts
with Mason's default substitution tag)

    <% $var = 'perl code'; %>

The substitution tag is this:

    <%= $var %>

Perl-lines are disabled by default.  I consider them syntactically
dangerous, but if you like them you can have them back by setting
the 'perl_lines' parameter to 1.

    my $interp = HTML::Mason::Interp->new( 
                 data_dir => '/here',
                 comp_root => '/there',
                 lexer_class => 'HTML::Mason::Lexer::MSP',
                 perl_lines => 1,
                 );

The last addition is JSP-style hidden comments, which begin with 
'<%--' and end with '--%>'.  The comments do not appear in the
component output, similar to a <%doc> section.  The comment may
contain any text except the ending tag.  If you need to put the
ending tag in, escape the last character like this: '--%\>'.

    <%-- this text will not appear in the output --%>

=head1 Other Syntax

Everything else is the same.

=head1 AUTHOR

John Williams, E<lt>williams@tni.comE<gt>

=head1 SEE ALSO

L<HTML::Mason::Lexer>.

=cut


