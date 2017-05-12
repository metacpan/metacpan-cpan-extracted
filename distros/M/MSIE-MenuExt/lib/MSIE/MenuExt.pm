package MSIE::MenuExt;

use strict;
use vars qw($VERSION);
$VERSION = 0.02;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(
  MENUEXT_DEFAULT
  MENUEXT_IMAGES
  MENUEXT_CONTROLS
  MENUEXT_TABLES
  MENUEXT_TEXT_SELECTIONS
  MENUEXT_ANCHORS
);

use constant MENUEXT_DEFAULT  => hex(1);
use constant MENUEXT_IMAGES   => hex(2);
use constant MENUEXT_CONTROLS => hex(4);
use constant MENUEXT_TABLES   => hex(8);
use constant MENUEXT_TEXT_SELECTIONS => hex(10);
use constant MENUEXT_ANCHORS         => hex(20);

sub new {
    my $class = shift;
    my $self = bless {
	actions => [],
    }, $class;
    if (@_) {
	$self->add_action($_) for @_;
    }
    return $self;
}

sub add_action {
    my($self, $action) = @_;
    push @{$self->{actions}}, $action;
}

sub clear_action {
    my $self = shift;
    $self->{actions} = [];
}

sub content {
    my $self = shift;
    return "REGEDIT4\r\n" . join "\r\n\r\n", map $_->content, @{$self->{actions}};
}

package MSIE::MenuExt::Action;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(title accesskey action context));

my $template;
BEGIN {
    $template = <<'EOF';
[HKEY_CURRENT_USER\Software\Microsoft\Internet Explorer\MenuExt\%s]
@="%s"
"contexts"=hex:%02x
EOF
    ;
    $template =~ s/\n/\r\n/g;
}

sub content {
    my $self = shift;
    my $title = $self->title;
    my $accesskey = $self->accesskey || substr($title, 0, 1);
    $title =~ s/$accesskey/&$accesskey/;
    return sprintf $template, $title, $self->action, $self->context;
}

1;
__END__

=head1 NAME

MSIE::MenuExt - Generates registry file (.reg) for MSIE Menu Extension

=head1 SYNOPSIS

  use CGI;
  use MSIE::MenuExt;

  my $action = MSIE::MenuExt::Action->new();
  $action->title('Blog It!');
  $action->accesskey('B');
  $action->action('javascript:external.menuArguments.blahblah()');
  $action->context(MENUEXT_DEFAULT + MENUEXT_TEXT_SELECTIONS);

  my $reg = MSIE::MenuExt->new();
  $reg->add_action($action);

  print CGI::header(-type => 'text/plain; name=blogit.reg',
                    -content_disposition => 'attachment; filename=blogit.reg');
  print $reg->content();

This example would print

  REGEDIT4
  [HKEY_CURRENT_USER\Software\Microsoft\Internet Explorer\MenuExt\&Blog It!]
  @="javascript:external.menuArguments.blahblah()"
  "contexts"=hex:11

=head1 DESCRIPTION

MSIE::MenuExt is a module to create Win32 registry file (.reg) to
register an action to Microsoft IE's Menu Extension.

=head1 METHODS

=over 4

=item new

  my $reg = MSIE::MenuExt->new();
  my $reg = MSIE::MenuExt->new(@actions);

constructs new MSIE::MenuExt object. If MSIE::MenuExt::Action objects
are given, it automaticaly calls C<add_action()>.

=item add_action

  $reg->add_action($action);

takes MSIE::MenuExt::Action object.

=item clear_action

  $reg->clear_action();

clears action objects holded inside.

=item content

  my $text = $reg->content();

returns content of the registry file as a string.

=back

=head1 MSIE::MenuExt::Action METHODS

=over 4

=item new

  my $action = MSIE::MenuExt::Action->new();
  my $action = MSIE::MenuExt::Action->new({
      title => 'Blog It!', acceskey => 'B',
      action => 'C:\file\js.htm', context => MENUEXT_DEFAULT,
  });

constructs new MSIE::MenuExt::Action object. If hash reference is
given, it sets these variables as a initial state.

=item title

  my $title = $action->title();
  $action->title($title);;

gets/sets the title of the action, which is displayed in a menu extension.

=item accesskey

  my $key = $action->accesskey();
  $action->accesskey($key);

gets/sets the accesskey of the action, which you can use for a
shortcut to the action. It uses the 1st string of its C<title>
attribute as a default.

=item action

  my $act = $action->action();
  $action=>action($act);

gets/sets the associated action, which can be a path of the executable
file or script.

=item context

  my $context = $action->context();
  $action->context($context);

gets/sets the context where the action can be executed. The following
constants can be used.

  MENUEXT_DEFAULT
  MENUEXT_IMAGES
  MENUEXT_CONTROLS
  MENUEXT_TABLES
  MENUEXT_TEXT_SELECTIONS
  MENUEXT_ANCHORS

If you put your actions in several contexts, just sum these context
constants like:

  $action->context(MENUEXT_DEFAULT + MENUEXT_TEXT_SELECTIONS);

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.siteexperts.com/tips/hj/ts01/index.asp

=cut
