package HTML::Obj2HTML::Plugin::SemanticUI;

use strict;
use warnings;

my @semanticnumbers = qw(zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen);
HTML::Obj2HTML::register_extension("segment", {
  tag => "div",
  attr => { class => "ui segment" }
});
HTML::Obj2HTML::register_extension("button", {
  attr => { class => "ui button" }
});



HTML::Obj2HTML::register_extension("help", {
  tag => "i",
  attr => {
    class => "blue circular icon help",
    style => "margin-left: 5px"
  },
  before => sub {
    my $o = shift;
    if ($o->{html}) {
      $o->{"data-html"} = $o->{html}; delete($o->{html});
    }
    if ($o->{text}) {
      $o->{"data-content"} = $o->{text}; delete($o->{text});
    }
    return "";
  }
});

HTML::Obj2HTML::register_extension("table", {
  before => sub {
    my $obj = shift;
    if (ref $obj eq "HASH") {
      if ($obj->{header}) {
        push(@{$obj->{_}}, thead => [ tr => HTML::Obj2HTML::iterate("th", $obj->{header}) ]);
        delete($obj->{header});
      }
      if ($obj->{rows}) {
        my @allrows;
        foreach my $r (@{$obj->{rows}}) {
          my @cols = ();
          foreach my $c (@{$r}) {
            push(@cols, td => $c);
          }
          push(@allrows, tr => \@cols);
        }
        push(@{$obj->{_}}, tbody => \@allrows);
        delete($obj->{rows});
      }
      return "";
    }
  },
  attr => { class => 'ui celled table' }
});

# Menus etc
HTML::Obj2HTML::register_extension("dropdownmenu", {
  tag => "div",
  attr => { class => "ui dropdown item" },
  before => sub {
    my $obj = shift;

    my $label = $obj->{label};
    delete($obj->{label});

    my $items = $obj->{items};
    foreach my $i (@{$items}) {
      if (ref $i eq "HASH") {
        if ($i->{class}) { $i->{class}.= " "; }
        $i->{class} .= "item";
      }
    }
    delete($obj->{items});

    $obj->{_} = [
      _ => $label." ",
      i => { class => "dropdown icon" },
      div => { class => "menu", _ => $items }
    ];
    return;
  }
});
HTML::Obj2HTML::register_extension("icon", {
  tag => "i",
  scalarattr => "class",
  attr => { class => "icon" }
});

HTML::Obj2HTML::register_extension("grid", {
  tag => "div",
  before => sub {
    my $o = shift;
    if (ref $o eq "HASH" && $o->{columns}) {
      if ($o->{class}) { $o->{class} .= " "; }
      $o->{class} .= $semanticnumbers[$o->{columns}]." column";
      delete($o->{columns});
      return "";
    }
  },
  attr => { class => "ui grid" }
});

HTML::Obj2HTML::register_extension("row", {
  tag => "div",
  attr => { class => "row" }
});

HTML::Obj2HTML::register_extension("column", {
  tag => "div",
  before => sub {
    my $o = shift;
    if (ref $o eq "HASH" && $o->{wide}) {
      if ($o->{class}) { $o->{class} .= " "; }
      $o->{class} .= $semanticnumbers[$o->{wide}]." wide";
      delete($o->{wide});
      return "";
    }
  },
  attr => { class => "column" }
});

HTML::Obj2HTML::register_extension("highlightbox", {
  tag => "div",
  attr => { class => "ui yellow message"}
});

1;
