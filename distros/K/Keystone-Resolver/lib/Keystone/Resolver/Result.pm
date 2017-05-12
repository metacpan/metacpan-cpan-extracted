# $Id: Result.pm,v 1.3 2008-04-25 17:45:52 mike Exp $

package Keystone::Resolver::Result;

use strict;
use warnings;


=head1 NAME

Keystone::Resolver::Result - a result, with its type, resolved from an OpenURL

=head1 SYNOPSIS

 $result = new OpenURL::Result("fulltext", "", "CQL Tutorial", 15,
                               "http://zing.z3950.org/cql/intro.html");
 $type = $result->type();
 $text = $result->text()

=head1 DESCRIPTION

A C<Keystone::Resolver::Result> object represents one of the
(potentially) many results found by resolving an OpenURL.  It can't do
anything useful apart from tell you the data with which it was
created, and render itself.  What we're looking for here is, I think,
what we doctors, in fact, call a C<struct>.

=head1 METHODS

=cut


=head2 new()

 $r1 = new OpenURL::Result("fulltext", "", "CQL web site", 10,
                           "http://zing/z3950.org/cql/");
 $r2 = new OpenURL::Result("bookstore", "", "Amazon", 25,
                           "isbn:0253333490");
 $r3 = new OpenURL::Result("citation", "JVP", "JVP format citation", 99,
                           "Wedel 2003.  <i>Paleobiology</i>.",
			   "text/html", 1);

Creates a new Keystone::Resolver::Result object with the specified
parameters.  A result is represented by the following components:

=over 4

=item type

A short string indicating the type of service that provided the
result, e.g. C<fulltext>, C<abstract>, C<websearch>, C<citation>.
These are intended to be recognised by XSLT stylesheets rather than
read by humans.

=item tag

A short string indicating the particular service that provided the
result.  This, too, is intended for stylesheets to compare with rather
than for humans: C<service> is the human-readable equivalent.  This
tag is useful for some types of service (e.g. C<citation>) but not
necessarily for others (e.g. C<fulltext>).

=item service

A short human-readable description of the service that provided the
result.

=item priority

An integer representing the priority of this result relative to others
of the same type.  Lower values represent higher priorities.

=item text

The text of the result itself.  Its form may vary depending on the
type of service that provided it.  For example, for C<fulltext> and
C<abstract> services, it's a URI; but for C<citation> services, it's
an HTML fragment.

=item text

The text of the result itself.  Its form may vary depending on the
type of service that provided it.  For example, for C<fulltext> and
C<abstract> services, it's a URI; but for C<citation> services, it's
an HTML fragment.

=item mimeType

(Optional)  An indication of the MIME-type of the text.

=item single

(Optional)  If provided and true, then this result is the only one
explicitly requested by the ContextObject.

=back

=cut

sub new {
    my $class = shift();
    my($type, $tag, $service, $priority, $text, $mimeType, $single) = @_;

    return bless {
	type => $type,
	tag => $tag,
	service => $service,
	priority => $priority,
	text => $text,
	mimeType => $mimeType,
	single => $single,
    }, $class;
}


=head2 type(), tag(), service(), priority(), text(), mimeType(), single()

 $type = $result->type();
 $text = $result->text();
 die if $type ne "fulltext" || $text ne "http://zing.z3950.org/cql/";

C<type()> returns the type of a C<Keystone::Resolver::Result>,
C<tag()> returns a tag for the name of the service that provides it,
C<service()> returns a description of the service, C<priority()>
returns its priority, C<text()> returns its text, C<mimeType()>
returns its mime-type and C<single()> returns an indication of whether
the result was the only one requested.  These are, respectively, the
first to seventh parameters with which it was created.

=cut

sub type { return shift()->{type} }
sub tag { return shift()->{tag} }
sub service { return shift()->{service} }
sub priority { return shift()->{priority} }
sub text { return shift()->{text} }
sub mimeType { return shift()->{mimeType} }
sub single { return shift()->{single} }


=head2 render()

 print $result->render(), "\n";

Returns a human-readable string representing a
C<Keystone::Resolver::Result>.

=cut

sub render() {
    my $this = shift();

    my $type = $this->type();
    my $tag = $this->tag();
    my $service = $this->service();
    my $priority = $this->priority();
    my $text = $this->text();

    return ("$type: " .
	    (defined $tag ? "$tag" : "") .
	    (defined $service ? "=$service" : "") .
	    (defined $priority ? " (priority $priority)" : "") .
	    " - $text");
}


1;
