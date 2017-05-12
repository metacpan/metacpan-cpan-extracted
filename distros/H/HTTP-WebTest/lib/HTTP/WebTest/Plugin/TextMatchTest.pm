# $Id: TextMatchTest.pm,v 1.8 2003/03/02 11:52:09 m_ilya Exp $

package HTTP::WebTest::Plugin::TextMatchTest;

=head1 NAME

HTTP::WebTest::Plugin::TextMatchTest - Test the content of the HTTP response.

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin supports test on the content of the HTTP response.  You can test
for the existence or non-existence of a literal string or a regular expression.

=cut

use strict;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 ignore_case

Option to do case-insensitive string matching for C<text_forbid>,
C<text_require>, C<regex_forbid> and C<regex_require> test parameters.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<no>

=head2 text_forbid

List of text strings that are forbidden to exist in the returned
page.

See also the C<regex_forbid> and C<ignore_case> parameters.

=head2 text_require

List of text strings that are required to exist in the returned
page.

See also the C<regex_require> and C<ignore_case> parameters.

=head2 regex_forbid

List of regular expressions that are forbidden to exist in the
returned page.

For more information, see L<perldoc perlre|perlre> or see Programming
Perl, 3rd edition, Chapter 5.

See also the C<text_forbid> and C<ignore_case> parameters.

=head2 regex_require

List of regular expressions that are required to exist in the
returned page.

For more information, see L<perldoc perlre|perlre> or see Programming Perl,
3rd edition, Chapter 5.

See also the C<text_require> and C<ignore_case> parameters.

=cut

sub param_types {
    return q(ignore_case   yesno
             text_forbid   list
             text_require  list
             regex_forbid  list
             regex_require list);
}

sub check_response {
    my $self = shift;

    # response content
    my $content = $self->webtest->current_response->content;

    $self->validate_params(qw(ignore_case
                              text_forbid text_require
                              regex_forbid regex_require));

    # ignore case or not?
    my $ignore_case = $self->yesno_test_param('ignore_case');
    my $case_re = $ignore_case ? '(?i)' : '';

    # test results
    my @results = ();
    my @ret = ();

    # check for forbidden text
    for my $text_forbid (@{$self->test_param('text_forbid', [])}) {
	my $ok = $content !~ /$case_re\Q$text_forbid\E/;

	push @results, $self->test_result($ok, $text_forbid);
    }

    push @ret, ['Forbidden text', @results] if @results;
    @results = ();

    # check for required text
    for my $text_require (@{$self->test_param('text_require', [])}) {
	my $ok = $content =~ /$case_re\Q$text_require\E/;

	push @results, $self->test_result($ok, $text_require);
    }

    push @ret, ['Required text', @results] if @results;
    @results = ();

    # check for forbidden regex
    for my $regex_forbid (@{$self->test_param('regex_forbid', [])}) {
	my $ok = $content !~ /$case_re$regex_forbid/;

	push @results, $self->test_result($ok, $regex_forbid);
    }

    push @ret, ['Forbidden regex', @results] if @results;
    @results = ();

    # check for required regex
    for my $regex_require (@{$self->test_param('regex_require', [])}) {
	my $ok = $content =~ /$case_re$regex_require/;

	push @results, $self->test_result($ok, $regex_require);
    }

    push @ret, ['Required regex', @results] if @results;
    @results = ();

    return @ret;
}

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson.  All rights reserved.

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
