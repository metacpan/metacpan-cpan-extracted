package HTML::Lister;

$VERSION = '0.01';

my $aryparams = '';
my $hashparams = '';

sub List {
    my $class = shift;
    $class->{'caller'} = 'List';
    my @list;
    push @list, sprintf "<ul%s>",
                        $aryparams ?
                          " $aryparams":
                          undef;
    while (@_) {
        my $val = shift;
        my $ref = ref $val;
        unless ($ref eq 'SCALAR' or
                $ref eq 'ARRAY' or
                $ref eq 'HASH' or
                $ref eq 'CODE' or
                $ref eq 'REF' or
                $ref eq 'GLOB' or
                $ref eq 'LVALUE' or
                !$ref) {
            my $refval = sprintf '%s', $val;
            my ($class,$type) = $refval =~ /^(.*)\=(.*)\(.*\)$/;
            $ref = $type;}
        push @list, sprintf "%s",
                            $ref ?
                              $ref eq 'SCALAR' ?
                                sprintf "<li>%s</li>", $$val :
                                $ref eq 'ARRAY' ?
                                  $class->List(@$val) :
                                  $ref eq 'HASH' ?
                                    $class->hashList(%$val) :
                                    sprintf "<li><b>%s</b></li>(%s)",
                                      $ref, $val :
                              "<li>$val</li>";}
    push @list, '</ul>';
    return join "\n", @list;}

sub oList {
    my $class = shift;
    $class->{'caller'} = 'oList';
    my @list;
    push @list, sprintf "<ol%s>",
                        $aryparams ?
                          " $aryparams":
                          undef;
    while (@_) {
        my $val = shift;
        my $ref = ref $val;
        unless ($ref eq 'SCALAR' or
                $ref eq 'ARRAY' or
                $ref eq 'HASH' or
                $ref eq 'CODE' or
                $ref eq 'REF' or
                $ref eq 'GLOB' or
                $ref eq 'LVALUE' or
                !$ref) {
            my $refval = sprintf '%s', $val;
            my ($class,$type) = $refval =~ /^(.*)\=(.*)\(.*\)$/;
            $ref = $type;}
        push @list, sprintf "%s",
                            $ref ?
                              $ref eq 'SCALAR' ?
                                sprintf "<li>%s</li>", $$val :
                                $ref eq 'ARRAY' ?
                                  $class->List(@$val) :
                                  $ref eq 'HASH' ?
                                    $class->hashList(%$val) :
                                    sprintf "<li><b>%s</b></li>(%s)",
                                      $ref, $val :
                              "<li>$val</li>";}
    push @list, '</ol>';
    return join "\n", @list;}

sub hashList {
    my $class = shift;
    my $caller = $class->{'caller'};
    my @list;
    my @stuff;
    if (ref $_[0] eq 'HASH') {
        while (my ($k,$v) = each %{$_[0]}) {
            push @stuff, $k, $v;}}
    else {
        @stuff = @_;}
    push @list, sprintf "<dl>%s",
                $hashparams ?
                  " $hashparams":
                  undef;
    while (@stuff) {
        push @list, sprintf "<dt>%s</dt>", shift(@stuff);
        my $val = shift @stuff;
        my $ref = ref $val;
        unless ($ref eq 'SCALAR' or
                $ref eq 'ARRAY' or
                $ref eq 'HASH' or
                $ref eq 'CODE' or
                $ref eq 'REF' or
                $ref eq 'GLOB' or
                $ref eq 'LVALUE' or
                !$ref) {
            my $refval = sprintf '%s', $val;
            my ($class,$type) = $refval =~ /^(.*)\=(.*)\(.*\)$/;
            $ref = $type;}
        push @list, sprintf "<dd>%s</dd>",
                            $ref ?
                              $ref eq 'SCALAR' ?
                                $$val :
                                $ref eq 'ARRAY' ?
                                  $caller eq 'oList' ?
                                    $class->oList(@$val) :
                                    $class->List(@$val) :
                                  $ref eq 'HASH' ?
                                    $class->hashList(%$val) :
                                    sprintf "<b>%s</b>(%s)",
                                      $ref, $val :
                              $val;}
    push @list, '</dl>';
    return join "\n", @list;}

sub new {
    my $class = shift;
    return bless {}, ref $class || $class; }

1||'Happy Happy, Joy Joy'; # 1s are so boring

=head1 NAME

HTML::Lister - Multidimensional Structure to HTML List Converter

=head1 SYNOPSIS

  use HTML::Lister;
  my $lister = new HTML::Lister;
  print "Content-type: text/html\n\n";
  print $lister->List($arrayref);
  print $lister->oList(@array);
  print $lister->hashList(%hash);
  print $lister->List($hashref);

=head1 DESCRIPTION

HTML::Lister is a small HTML utility that addresses a built-in function that CGI.pm has left
unaddressed -- it handles multidimensional objects, calling itself recursively to create an
HTML list entity from the contents.

Honestly, I hacked this thing together quickly out of need, but it's becomes somehting I use
on a regular basis, debugging CGI scripts live through a browser and so on.

Put then again, that's where Perl itself came from!

=head1 METHODS

=over 4

=item new() (constructor method)

This is just the typical constructor method. It currently takes no arguments and provides no options.

=item List()

List() is the primary method of Lister. It takes any array, arrayref, hashref, or scalar value
(though the latter is admittedly pointless) and makes an unordered list (UL entity) out of what
it gets.

If it receives a hashref, it calls hashList on the dereferences hashref, making an unordered
list with no LI entities, but with a definition list inside it. This has the potentially annoying
side effect of indenting any lone hashref it's handed, but it will still work and doesn't matter for
debugging purposes, which is Lister's main utilisation. If you want to avoid this, hand it off to
hashList() instead.

An array or arrayref handed to List will create a proper bulleted unordered list. A scalar or
scalarref handed off to List() will return a list of one item.

If List() encounters a reference in any of its argument list, it will dereference it and call the
appropriate method on that item if it dereferences to an array or hash. If it's a hashref, it will
call hashList. If it's an array, it will call itself. That's also why just handing it a hashref
works, but handing it a real hash won't -- the keys and values end up as @_ as an array.

Oh, yeah -- a plain list or listref works nicely, too. (It's an array -- @_ -- by the time the
method sees it anyway, which is also why handing it a hash won't work).

=item oList()

The oList() method works just like the List() method, except that the lists it creates are
HTML OL entities -- that is, ordered lists. That means they're numbered (or lettered, or whatever,
depending on their nestedness).

It should be noted somewhere (and here seems like a good place) that if you call oList, and oList
finds a hashref, and that hash contains an arrayref, the object will in fact remember where it
came from and call oList again, not List. In other words, if you start with numbered lists, you
will get numbered lists all the way in. If you start with bulleted lists, you will get bulleted
lists all the way in. This is to be considered cool.

=item hashList()

The hashList() method takes a hash or hashref as an argument. You can use it in a utility fashion,
if you want, and hand it an array or list, too, and it may give you what you expect. Handing it
an arrayref or listref almost definitely will *not* do what you want. hashList creates an HTML
definition list (DL entity). The keys become DT entities and the values become DD entities. In the
case of handing it an array or list, the even-indexed items become DTs and the odd-indexed items
become DDs.

As with the other two methods, hashList() recognises when it encounters a reference, dereferences it,
and calls the appropriate method on it. If it is called explicitly, sub-lists will be UL entities
(bulleted lists).

Do not hand hashList a blessed hashref... it won't work. Dereference it first (i.e. hashList(%$cgi)
or hand it off through List, which will do the job for you. Honestly, I'm still scratching my head
on this one. I'm sure there's a perfectly rational explanation, and I think I have come up with it
on a number of occassions, but I never remember when the Sudafed and NyQuil wear off.

=item notes on all methods

None of these methods are intended for use with other kinds of references. They won't break it,
but you will simply get GLOB(0x80f1098) or CODE(0x80fd9d8) or whatever. It can't see past that
point. Nevertheless, this is a far cry better than the listing functions built into CGI.pm right
now (no offense to that wonderful module that I use all the time or it's writers or maintainers --
you can't do everything).

=item CSS support and additional tag parametres

I'll admit this is badly kludged in. You can access the variables $HTML::Lister::aryparams and
$HTML::Lister::hashparams directly to set up additional paramatres for the HTML code created.
Whatever is in these variables will appear in the entity's tag, right after the *l -- thus you
will want to start anything you put here with a space.

For instance, to set a CSS class on your definition lists, you might do this:
$HTML::Lister::hashparams = ' class="purdy"'
and your HTML entity will look like this:
<dl class="purdy">

These default to '', so the list entities default to being a plain tag ('<ul>,<dl>,<ol>')

=back

=head1 TO DO LIST

It would be nice if I could get some help building a non-OO version of this, too. However, I'm not
sure how that would work since some parts, like remembering what called it, is implicitly OO in
approach. This way it could be wrapped into CGI.pm and thus be much more widely used.

I should also give some thought to a better approach to setting up tag parametres, and supporting
the sub-entity parametres as well (the DT, DD, and LI items).

I'd love it if someone would help me find an easy way to get at the actual stuff of other types of
references, like displaying the first 160 characters of code in a PRE tag for a coderef, or some
easy way to list all the associated entities of a glob ref.

Figure out that blasted blessed hashList issue. And remember the answer later.

Figure out why all the Denny'ses are closing down.

Figure out how to properly pluralise an inherently possessive proper noun.

=head1 AUTHOR

Dodger (Sean Cannon) dodger@dodger.org

Contact me if you want to help or patch anything on the TO DO list.

=head1 LICENCE

Umm, call it the Artistic Licence. I hate the legal crap part. Dammit, Jim, I'm a programmer,
not a lwayer.

This module is implicitly and explicitly distributed under the Perl Artistic Licence.
All rights reserved, all rites reversed.

=head1 SEE ALSO

perl(1), CGI(3)

=cut
