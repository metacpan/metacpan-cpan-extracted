# Library of perl functions for use by WebMake scripts.

=head1 NAME

PerlCodeLibrary - a selection of functions for use by perl code embedded in a
WebMake file.

=head1 SYNOPSIS

  <{perl

    $foo = get_content ($bar);
    [... etc.]

    # or:

    $foo = $self->get_content ($bar);
    [... etc.]

  }>

=head1 DESCRIPTION

These functions allow code embedded in a <{perl}> or <{perlout}> section of a
WebMake file to be used to script the generation of content.

Each of these functions is defined both as a standalone function, or as a
function on the PerlCode object.  Code in one of the <{perl*}> sections can
access this PerlCode object as the C<$self> variable.  If you plan to use
WebMake from mod_perl or in a threaded environment, be sure to call them as
methods on C<$self>.

=head1 METHODS

=over 4

=cut

package HTML::WebMake::PerlCode;

use Carp;
use strict;

###########################################################################

=item $expandedtext = expand ($text);

Expand a block of text, interpreting any references, user tags, or
any other WebMake markup contained within.

=cut

sub expand {
  my ($self, $text) = @_;
  return $self->{main}->fileless_subst ($HTML::WebMake::Main::SUBST_EVAL, $text);
}

# -------------------------------------------------------------------------

=item @names = content_matching ($pattern);

Find all items of content that match the glob pattern C<$pattern>.  If
C<$pattern> begins with the prefix B<RE:>, it is treated as a regular
expression.  The list of items returned is not in any logical order.

=cut

sub content_matching {
  my ($self, $patt) = @_;

  $patt = $self->{main}->{util}->glob_to_re ($patt);
  my @ret = grep (m/${patt}/, $self->{main}->get_all_content_names());
  @ret;
}

# -------------------------------------------------------------------------

=item @objs = content_names_to_objects (@names);

Given a list of content names, convert to the corresponding list of content
objects, ie. objects of type C<HTML::WebMake::Content>.

=cut

sub content_names_to_objects {
  my ($self, @namelist) = @_;
  my @list = ();
  foreach my $elem (@namelist) {
    my $contobj = $self->{main}->get_content_obj($elem);
    if (!defined $contobj) {
      warn "content_names_to_objects: not a <content> item: $elem\n";
      next;
    }
    push (@list, $contobj);
  }
  @list;
}

# -------------------------------------------------------------------------

=item $obj = get_content_object ($name);

Given a content name, convert to the corresponding content object, ie. objects
of type C<HTML::WebMake::Content>.

=cut

sub get_content_object {
  my ($self, $name) = @_;
  my $contobj = $self->{main}->get_content_obj($name);
  if (!defined $contobj) {
    warn "get_content_object: not a <content> item: $name\n";
  }
  $contobj;
}

# -------------------------------------------------------------------------

=item @names = content_objects_to_names (@objs);

Given a list of objects of type C<HTML::WebMake::Content>, convert to
the corresponding list of content name strings.

=cut

sub content_objects_to_names {
  my ($self, @objlist) = @_;
  local ($_);
  map { $_->get_name() } @objlist;
}

# -------------------------------------------------------------------------

=item @sortedobjs = sort_content_objects ($sortstring, @objs);

Sort a list of content objects by the sort string C<$sortstring>.
See ''sorting.html'' in the WebMake documentation for details on
sort strings.

=cut

sub sort_content_objects {
  my ($self, $sortstr, @list) = @_;
  my $sortsub = $self->get_sort_sub($sortstr);
  sort $sortsub (@list);
}

# -------------------------------------------------------------------------

=item @names = sorted_content_matching ($sortstring, $pattern);

Find all items of content that match the glob-style pattern C<$pattern>.  The
list of items returned is ordered according to the sort string C<$sortstring>.
If C<$pattern> begins with the prefix B<RE:>, it is treated as a regular
expression.

See ''sorting.html'' in the WebMake documentation for details on sort strings.

This, by the way, is essentially implemented as follows:

	my @list = $self->content_matching ($pattern);
	@list = $self->content_names_to_objects (@list);
	@list = $self->sort_content_objects ($sortstring, @list);
	return $self->content_objects_to_names (@list);

=cut

sub sorted_content_matching {
  my ($self, $string, $patt) = @_;

  my @list = $self->content_matching ($patt);
  @list = $self->content_names_to_objects (@list);
  @list = $self->sort_content_objects ($string, @list);
  return $self->content_objects_to_names (@list);
}

# -------------------------------------------------------------------------

=item $str = get_content ($name);

Get the item of content named C<$name>.  Equivalent to a $ {content_reference}.

=cut

sub get_content {
  my ($self, $key) = @_;
  if (!defined $key) { croak ("get_content with undef key"); }
  my $str = $self->{main}->curly_or_meta_subst ($HTML::WebMake::Main::SUBST_EVAL, $key);
  $str;
}

=item @list = get_list ($name);

Get the item of content named, but in Perl list format. It is assumed that the
list is stored in the content item in whitespace-separated format.

=cut

sub get_list {
  my ($self, $key) = @_;
  if (!defined $key) { croak ("get_list with undef key"); }
  my $str = $self->{main}->curly_or_meta_subst ($HTML::WebMake::Main::SUBST_EVAL, $key);
  split (' ', $str);
}

=item set_content ($name, $value);

Set a content chunk to the value provided. This content will not appear in a
sitemap, and navigation links will never point to it.

Returns the content object created.

=cut

sub set_content {
  my ($self, $key, $val) = @_;
  if (!defined $key) { croak ("set_content with undef key"); }
  if (!defined $val) { croak ("set_content with undef val"); }
  return $self->{main}->set_unmapped_content ($key, $val);
}

=item set_list ($name, @values);

Set a content chunk to a list containing the values provided, separated by
spaces. This content will not appear in a sitemap, and navigation links will
never point to it.

Returns the content object created.

=cut

sub set_list {
  my ($self, $key, @vals) = @_;
  if (!defined $key) { croak ("set_list with undef key"); }
  return $self->{main}->set_unmapped_content ($key,
  				join (' ', @vals));
}

=item set_mapped_content ($name, $value, $upname);

Set a content chunk to the value provided. This content will appear in a
sitemap and the navigation hierarchy. C<$upname> should be the name of it's
parent content item.  This item must not be metadata, or other
dynamically-generated content; only first-class mapped content can be used.

Returns the content object created.

=cut

sub set_mapped_content {
  my ($self, $key, $val, $upname) = @_;
  if (!defined $key) { croak ("set_mapped_content with undef key"); }
  if (!defined $val) { croak ("set_mapped_content with undef val"); }
  if (!defined $upname) { croak ("set_mapped_content with undef upname"); }
  return $self->{main}->set_mapped_content ($key, $val, $upname);
}

=item del_content ($name);

Delete a named content chunk.

=cut

sub del_content {
  my ($self, $key) = @_;
  if (!defined $key) { croak ("del_content with undef key"); }
  $self->{main}->del_content ($key);
}

# -------------------------------------------------------------------------

=item @names = url_matching ($pattern);

Find all URLs (from <out> and <media> tags) whose name matches the glob-style
pattern C<$pattern>.  The names of the URLs, not the URLs themselves, are
returned.  If C<$pattern> begins with the prefix B<RE:>, it is treated as a
regular expression.

=cut

sub url_matching {
  my ($self, $patt) = @_;

  $patt = $self->{main}->{util}->glob_to_re ($patt);
  my @ret = grep (m/${patt}/, $self->{main}->get_all_url_names());
  @ret;
}

=item $url = get_url ($name);

Get a named URL. Equivalent to an $ (url_reference).

=cut

sub get_url {
  my ($self, $key) = @_;
  if (!defined $key) { croak ("get_url with undef key"); }
  $self->{main}->round_subst ($HTML::WebMake::Main::SUBST_EVAL, $key);
}

=item set_url ($name, $url);

Set an URL to the value provided.

=cut

sub set_url {
  my ($self, $key, $val) = @_;
  if (!defined $key) { croak ("get_url with undef key"); }
  if (!defined $val) { croak ("get_url with undef val"); }
  $self->{main}->add_url ($key, $val);
}

=item del_url ($name);

Delete an URL.

=cut

sub del_url {
  my ($self, $key) = @_;
  if (!defined $key) { croak ("del_url with undef key"); }
  $self->{main}->del_url ($key);
}

# -------------------------------------------------------------------------

=item $listtext = make_list ($itemname, @namelist);

Generate a list by iterating through the C<@namelist>, setting the content item
C<item> to the current name, and interpreting the content chunk named
C<$itemname>. This content chunk should refer to C<${item}> appropriately.

Each resulting block of content is appended to a $listtext, which is finally
returned.

See the C<news_site.wmk> sample site for an example of this in use.

=cut

sub make_list {
  my ($self, $list_item_name, @story_list) = @_;

  my @listtext = ();
  foreach my $story (@story_list) {
    $self->set_content ("item", $story);
    push (@listtext, $self->get_content ($list_item_name));
  }
  join ('', @listtext);
}

# -------------------------------------------------------------------------

sub _make_sitemap {
  my ($self, $topname, $map_generated_content, $contname) = @_;
  my $top = undef;

  if (defined $topname) {
    $top = $self->{main}->get_content_obj($topname);
    if (!defined $top) {
      warn "make_sitemap: <content> item not found: $topname\n";
      return "";
    }
  }

  $self->{main}->getmapper()->map_site ($top,
  			$map_generated_content, $contname);
}

sub make_sitemap {
  my ($self, $topname, $contname) = @_;
  $self->_make_sitemap ($topname, 0, $contname);
}

sub make_contentmap {
  my ($self, $topname, $contname) = @_;
  $self->_make_sitemap ($topname, 1, $contname);
}

# -------------------------------------------------------------------------

=item define_tag ($tagname, \&handlerfn, @required_attributes);

Define a tag for use in content items.  Any occurrences of this tag, with at
least the set of attributes defined in @required_attributes, will cause the
handler function referred to by handlerfn to be called.

Handler functions are called as fcllows:

	handler ($tagname, $attrs, $text, $perlcode);

Where $tagname is the name of the tag, $attrs is a reference to a hash
containing the attribute names and the values used in the tag, and $text is the
text between the start and end tags.

$perlcode is the PerlCode object, allowing you to write proper object-oriented
code that can be run in a threaded environment or from mod_perl. This can be
ignored if you like.

This function returns an empty string.

=cut

sub define_tag {
  my ($self, $name, $fnname, @reqdattrs) = @_;
  $self->{main}->getusertags()->def_tag (0,0,0, $name, $fnname, @reqdattrs);
}

=item define_empty_tag ($tagname, \&handlerfn, @required_attributes);

Define a tag for use in content items.  This is identical to define_tag above,
but is intended for use to define ''empty'' tags, ie. tags which occur alone,
not as part of a start and end tag pair.

The handler in this case is called with an empty string for the $text
argument.

=cut

sub define_empty_tag {
  my ($self, $name, $fnname, @reqdattrs) = @_;
  $self->{main}->getusertags()->def_tag (1,0,0, $name, $fnname, @reqdattrs);
}

# -------------------------------------------------------------------------

=item define_preformat_tag ($tagname, \&handlerfn, @required_attributes);

Identical to L<define_tag>, above, with one difference; these tags will
be interpreted B<before> the content undergoes any format conversion.

=cut

sub define_preformat_tag {
  my ($self, $name, $fnname, @reqdattrs) = @_;
  $self->{main}->getusertags()->def_tag (0,0,1, $name, $fnname, @reqdattrs);
}

=item define_empty_preformat_tag ($tagname, \&handlerfn, @required_attributes);

Identical to L<define_empty_tag>, above, with one difference; these tags will
be interpreted B<before> the content undergoes any format conversion.

=cut

sub define_empty_preformat_tag {
  my ($self, $name, $fnname, @reqdattrs) = @_;
  $self->{main}->getusertags()->def_tag (1,0,1, $name, $fnname, @reqdattrs);
}

# -------------------------------------------------------------------------

=item define_wmk_tag ($tagname, \&handlerfn, @required_attributes);

Define a tag for use in the WebMake file.

Aside from operating on the WebMake file instead of inside content items, this
is otherwise identical to define_tag above,

=cut

sub define_wmk_tag {
  my ($self, $name, $fnname, @reqdattrs) = @_;
  $self->{main}->getusertags()->def_tag (0,1,0, $name, $fnname, @reqdattrs);
}

=item define_empty_wmk_tag ($tagname, \&handlerfn, @required_attributes);

Define an empty, aka. standalone, tag for use in the WebMake file.

Aside from operating on the WebMake file instead of inside content items, this
is otherwise identical to define_tag above,

=cut

sub define_empty_wmk_tag {
  my ($self, $name, $fnname, @reqdattrs) = @_;
  $self->{main}->getusertags()->def_tag (1,1,0, $name, $fnname, @reqdattrs);
}

# -------------------------------------------------------------------------

=item $obj = get_root_content_object();

Get the content object representing the ''root'' of the site map.  Returns
undef if no root object exists, or the WebMake file does not contain a
&lt;sitemap&gt; command.

=cut

sub get_root_content_object {
  my ($self) = @_;
  return $self->{main}->getmapper()->get_root();
}

# -------------------------------------------------------------------------

=item $name = get_current_main_content();

Get the ''main'' content on the current output page.  The ''main'' content is
defined as the most recently referenced content item which (a) is not generated
content (perl code, sitemaps, breadcrumb trails etc.), and (b) has its
C<map> attribute set to "true".

Note that this API should only be called from a deferred content reference;
otherwise the ''main'' content item may not have been referenced by the time
this API is called.

C<undef> is returned if no main content item has been referenced.

=cut

sub get_current_main_content {
  my ($self) = @_;
  $self->{main}->curly_subst ($HTML::WebMake::Main::SUBST_EVAL, "__MainContentName");
}

# -------------------------------------------------------------------------

=item $main = get_webmake_main_object();

Get the current WebMake interpreter's instance of C<HTML::WebMake::Main>
object. Virtually all of WebMake's functionality and internals can be accessed
through this.

=cut

sub get_webmake_main_object {
  my ($self) = @_;
  $self->{main};
}

# -------------------------------------------------------------------------
# Glue functions -- these allow calls from perl code without using the
# $self->function_name() OO mode.

package main;

sub content_matching {
  $HTML::WebMake::PerlCode::GlobalSelf->content_matching(@_);
}
sub sorted_content_matching {
  $HTML::WebMake::PerlCode::GlobalSelf->sorted_content_matching(@_);
}
sub sort_content_list {
  $HTML::WebMake::PerlCode::GlobalSelf->sort_content_list(@_);
}
sub set_mapped_content {
  $HTML::WebMake::PerlCode::GlobalSelf->set_mapped_content(@_);
}

sub get_content { $HTML::WebMake::PerlCode::GlobalSelf->get_content(@_); }
sub get_list { $HTML::WebMake::PerlCode::GlobalSelf->get_list(@_); }
sub set_content { $HTML::WebMake::PerlCode::GlobalSelf->set_content(@_); }
sub set_list { $HTML::WebMake::PerlCode::GlobalSelf->set_list(@_); }
sub del_content { $HTML::WebMake::PerlCode::GlobalSelf->del_content(@_); }
sub url_matching { $HTML::WebMake::PerlCode::GlobalSelf->url_matching(@_); }
sub get_url { $HTML::WebMake::PerlCode::GlobalSelf->get_url(@_); }
sub set_url { $HTML::WebMake::PerlCode::GlobalSelf->set_url(@_); }
sub del_url { $HTML::WebMake::PerlCode::GlobalSelf->del_url(@_); }
sub make_list { $HTML::WebMake::PerlCode::GlobalSelf->make_list(@_); }
sub content_names_to_objects
{ $HTML::WebMake::PerlCode::GlobalSelf->content_names_to_objects(@_); }
sub get_content_object
{ $HTML::WebMake::PerlCode::GlobalSelf->get_content_object(@_); }
sub sort_content_objects
{ $HTML::WebMake::PerlCode::GlobalSelf->sort_content_objects(@_); }
sub content_objects_to_names
{ $HTML::WebMake::PerlCode::GlobalSelf->content_objects_to_names(@_); }
sub define_tag
{ $HTML::WebMake::PerlCode::GlobalSelf->define_tag(@_); }
sub define_empty_tag
{ $HTML::WebMake::PerlCode::GlobalSelf->define_empty_tag(@_); }
sub define_preformat_tag
{ $HTML::WebMake::PerlCode::GlobalSelf->define_preformat_tag(@_); }
sub define_empty_preformat_tag
{ $HTML::WebMake::PerlCode::GlobalSelf->define_empty_preformat_tag(@_); }
sub define_wmk_tag
{ $HTML::WebMake::PerlCode::GlobalSelf->define_wmk_tag(@_); }
sub define_empty_wmk_tag
{ $HTML::WebMake::PerlCode::GlobalSelf->define_empty_wmk_tag(@_); }
sub get_root_content_object
{ $HTML::WebMake::PerlCode::GlobalSelf->get_root_content_object(@_); }
sub get_current_main_content
{ $HTML::WebMake::PerlCode::GlobalSelf->get_current_main_content(@_); }
sub get_webmake_main_object
{ $HTML::WebMake::PerlCode::GlobalSelf->get_webmake_main_object(@_); }
sub expand
{ $HTML::WebMake::PerlCode::GlobalSelf->expand(@_); }

1;
