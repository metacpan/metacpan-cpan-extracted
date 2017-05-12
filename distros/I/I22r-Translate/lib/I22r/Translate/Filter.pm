package I22r::Translate::Filter;
use Moose::Role;
our $VERSION = '0.96';
requires 'apply';
requires 'unapply';
1;

=head1 NAME

I22r::Translate::Filter - Role for translation I<filters>.

=head1 SYNOPSIS

To use a Filter on all translations

    I22r::Translate->config(
        filter => [  filter1, filter2, ... ],
        ... other config ...
    )

To use a Filter with a specific backend

    I22r::Translate->config(
        'My::Backend' => {
            filter => [  filter3, ... ],
            ... other backend config ...
        }
        ... other global config ...
    }

To use a Filter on a specific translation request

    I22r::Translate->translate_string(
        src => ..., dest => ..., text => ...,
        filter => [ filter4, ... ] );

(the C<filter> option is also recognized with the
C<< I22r::Translate->translate_list >> or
C<< I22r::Translate->translate_hash >> methods.

=head1 DESCRIPTION

Sometimes you do not want to pass a piece of text directly to
a translation engine. The text might contain HTML tags or 
other markup. It might contain proper nouns or other words that
you don't intend to translate. Classes that implement the
C<I22r::Translate::Filter> role can be used to adjust the
text before it is passed to a translation engine, and to 
unadjust the translator's output.

=head1 METHODS

=head2 apply

=head2 $filter->apply( $request, $key )

Accepts a L<I22r::Translate::Request> object and a key from
the input. Sanitizes C<< $req->text->{$key} >> for use in a
translation backend and keeps a record of what modifications
were made, so they can be unmade in the L<"unapply"> method
on the translator output.

=head2 unapply

=head2 $filter->unapply( $request, $key )

Modifies backend output in C<< $req->results->{$key}->text >>
to restore whatever changes were made to the backend input
in the L<"apply"> method.

=head1 DEVELOPMENT GUIDE

A new filter must implement the C<apply> and C<unapply>
methods. The filter must track the modifications made
to input in the C<apply> method, including the correct
order of modifications, so that those modifications
may be undone in the correct order in the C<unapply>
method.

The source code for the L<I22r::Translate::Filter::Literal>
and L<I22r::Translate::Filter::HTML> filters are currently
the best places to look for examples of how this can be
done.

=head1 SEE ALSO

L<I22r::Translate>, L<I22r::Translate::Filter::Literal>,
L<I22r::Translate::Filter::HTML>

=cut
