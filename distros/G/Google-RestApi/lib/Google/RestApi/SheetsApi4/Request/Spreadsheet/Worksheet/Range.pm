package Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range;

our $VERSION = '1.0.2';

use Google::RestApi::Setup;

use Scalar::Util qw( looks_like_number );
use aliased "Google::RestApi::SheetsApi4::Range";
use parent "Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet";

sub range { LOGDIE "Pure virtual function 'range' must be overridden"; }

sub left { shift->horizontal_alignment('LEFT'); }
sub center { shift->horizontal_alignment('CENTER'); }
sub right { shift->horizontal_alignment('RIGHT'); }
sub horizontal_alignment { shift->user_entered_format({ horizontalAlignment => shift }); }

sub top { shift->vertical_alignment('TOP'); }
sub middle { shift->vertical_alignment('MIDDLE'); }
sub bottom { shift->vertical_alignment('BOTTOM'); }
sub vertical_alignment { shift->user_entered_format({ verticalAlignment => shift }); }

sub font_family { shift->text_format({ fontFamily => shift }); }
sub font_size { shift->text_format({ fontSize => shift }); }
sub bold { shift->text_format({ bold => bool(shift) }); }
sub italic { shift->text_format({ italic => bool(shift) }); }
sub strikethrough { shift->text_format({ strikethrough => bool(shift) }); }
sub underline { shift->text_format({ underline => bool(shift) }); }

sub _rgba { shift->color({ (shift) => (shift // 1) }); }
sub red { shift->_rgba('red' => shift); }
sub blue { shift->_rgba('blue' => shift); }
sub green { shift->_rgba('green' => shift); }
sub alpha { shift->_rgba('alpha' => shift); }
sub black { shift->color(cl_black()); }
sub white { shift->color(cl_white()); }
sub color { shift->text_format({ foregroundColor => shift }); }

sub _bk_rgba { shift->bk_color({ (shift) => (shift // 1) }); }
sub bk_red { shift->_bk_rgba('red' => shift); }
sub bk_blue { shift->_bk_rgba('blue' => shift); }
sub bk_green { shift->_bk_rgba('green' => shift); }
sub bk_alpha { shift->_bk_rgba('alpha' => shift); }
sub bk_black { shift->bk_color(cl_black()); }
sub bk_white { shift->bk_color(cl_white()); }
sub bk_color { shift->user_entered_format({ backgroundColor => shift }); }

sub text { shift->number_format('TEXT', @_); }
sub number { shift->number_format('NUMBER', @_); }
sub percent { shift->number_format('PERCENT', @_); }
sub currency { shift->number_format('CURRENCY', @_); }
sub date { shift->number_format('DATE', @_); }
sub time { shift->number_format('TIME', @_); }
sub date_time { shift->number_format('DATE_TIME', @_); }
sub scientific { shift->number_format('SCIENTIFIC', @_); }
sub number_format {
  shift->user_entered_format(
    {
      numberFormat => {
        type => shift,
        defined $_[0] ? (pattern => shift) : ()
      }
    },
  );
}

sub padding { my $s = shift; my %p = @_; $s->user_entered_format({ padding => \%p }); }

sub overflow { shift->wrap_strategy('OVERFLOW_CELL'); }
sub clip { shift->wrap_strategy('CLIP'); }
sub wrap { shift->wrap_strategy('WRAP'); }
sub wrap_strategy { shift->user_entered_format({ wrapStrategy => shift }); }

sub left_to_right { shift->text_direction('LEFT_TO_RIGHT'); }
sub right_to_left { shift->text_direction('RIGHT_TO_LEFT'); }
sub text_direction { shift->user_entered_format({ textDirection => shift }); }

sub rotate { shift->text_rotation({ angle => shift }); }
sub vertical { shift->text_rotation({ vertical => bool(shift) }); }
sub text_rotation { shift->user_entered_format({ textRotation => shift }); }

sub hyper_linked { shift->user_entered_format({ hyperlinkDisplayType => 'LINKED' }); }
sub hyper_plain { shift->user_entered_format({ hyperlinkDisplayType => 'PLAIN_TEXT' }); }

sub text_format {
  my $self = shift;
  my ($format, $fields) = @_;
  ($fields) = each %$format if !defined $fields;
  $self->user_entered_format(
     { textFormat => $format },
    'textFormat.' . $fields,
  );
}

sub user_entered_format {
  my $self = shift;
  my ($format, $fields) = @_;
  ($fields) = each %$format if !defined $fields;
  $self->repeat_cell(
    cell => {
      userEnteredFormat => $format,
    },
    fields => 'userEnteredFormat.' . $fields,
  );
  return $self;
}

sub repeat_cell {
  my $self = shift;

  state $check = compile_named(
    cell   => HashRef,
    fields => Str, { optional => 1 },
  );
  my $p = $check->(@_);

  my $cell = $p->{cell};
  my $fields = $p->{fields} || join(',', sort keys %$cell);

  $self->batch_requests(
    repeatCell => {
      range  => $self->range_to_index(),
      cell   => $cell,
      fields => $fields,
    },
  );

  return $self;
}

sub heading {
  my $self = shift;
  $self->center()->bold()->white()->bk_black()->font_size(12);
  return $self;
}

sub _bd { shift->borders(properties => shift, border => (shift||'')); };
sub bd_red { shift->_bd_rbga('red' => shift, @_); }
sub bd_blue { shift->_bd_rbga('blue' => shift, @_); }
sub bd_green { shift->_bd_rbga('green' => shift, @_); }
sub bd_alpha { shift->_bd_rbga('alpha' => shift, @_); }
sub bd_black { shift->bd_color(cl_black(), @_); }
sub bd_white { shift->bd_color(cl_white(), @_); }
sub bd_color { shift->_bd({ color => shift }, @_); }

sub bd_dotted { shift->bd_style('DOTTED', @_); }
sub bd_dashed { shift->bd_style('DASHED', @_); }
sub bd_solid { shift->bd_style('SOLID', @_); }
sub bd_medium { shift->bd_style('SOLID_MEDIUM', @_); }
sub bd_thick { shift->bd_style('SOLID_THICK', @_); }
sub bd_double { shift->bd_style('DOUBLE', @_); }
sub bd_none { shift->bd_style('NONE', @_); }
sub bd_style { shift->_bd({ style => shift }, @_); }

# allows:
#   bd_red()  turns it all on
#   bd_red(0)  turns it all off
#   bd_red(0.3, 'top')
#   bd_red(0.3)
#   bd_red('top')
sub _bd_rbga {
  my $self = shift;
  my $color = shift;
  my $value;
  $value = shift if looks_like_number($_[0]);
  $value //= 1;
  return $self->bd_color({ $color => $value }, @_);
}

# borders can be set for a range or each individual cell
# in a range. bd_repeat_cell is turned on to redirect
# border calls to repeat_cell above.
sub bd_repeat_cell {
  my $self = shift;
  $self->{bd_repeat_cell} = shift;
  $self->{bd_repeat_cell} //= 1; # bd_repeat_cell() turns it on, bd_repeat_cell(0) turns it off.
  delete $self->{bd_repeat_cell} if !$self->{bd_repeat_cell};
  return $self;
}

sub borders {
  my $self = shift;

  # allow an array of borders to be passed, recurse with each one.
  my %p = @_;
  if ($p{border} && ref($p{border}) eq 'ARRAY') {
    $self->borders(border => $_, properties => $p{properties})
      foreach (@{ $p{border} });
    return $self;
  }

  state $check = compile_named(
    border     =>
      StrMatch[qr/^(top|bottom|left|right|around|vertical|horizontal|inner|all|)$/],
      { default => 'around' },
    properties => HashRef,
  );
  my $p = $check->(@_);
  $p->{border} ||= 'around';

  # recurse with border groups.
  my %groups = (
    around => [qw(top bottom left right)],
    inner  => [qw(vertical horizontal)],
    all    => [qw(around inner)],
  );
  my $group = $groups{ $p->{border} };
  if ($group) {
    $self->borders(border => $_, properties => $p->{properties})
      foreach (@$group);
    return $self;
  }

  # now we finally get to the guts of the borders.
  # if these borders are to be part of repeatCell request, redirect
  # the borders to it.
  if ($self->{bd_repeat_cell}) {
    LOGDIE "Cannot use vertical|horizontal|inner when bd_repeat_cell is turned on"
      if $p->{border} =~ /^(vertical|horizontal|inner)$/;
    return $self->user_entered_format(
      {
        borders => {
          $p->{border} => $p->{properties},
        }
      },
    );
  }

  # change vertical to innerVertical. horizontal same same.
  $p->{border} =~ s/^(vertical|horizontal)$/"'inner' . '" . ucfirst($1) . "'"/ee;

  $self->batch_requests(
    updateBorders => {
      range        => $self->range_to_index(),
      $p->{border} => $p->{properties},
    }
  );

  return $self;
}

sub merge_cols { shift->merge_cells(merge_type => 'col'); }
sub merge_rows { shift->merge_cells(merge_type => 'row'); }
sub merge_all { shift->merge_cells(merge_type => 'all'); }
sub merge_both { merge_all(@_); }
sub merge_cells {
  my $self = shift;

  state $check = compile_named(
    merge_type => DimColRow | DimAll,
  );
  my $p = $check->(@_);
  $p->{merge_type} = dims_all($p->{merge_type});

  $self->batch_requests(
    mergeCells => {
      range     => $self->range_to_index(),
      mergeType => "MERGE_$p->{merge_type}",
    },
  );

  return $self;
}

sub unmerge { unmerge_cells(@_); }
sub unmerge_cells {
  my $self = shift;
  $self->batch_requests(
    unmergeCells => {
      range => $self->range_to_index(),
    },
  );
  return $self;
}

sub insert_d { shift->insert_dimension(dimension => shift, inherit => shift); }
sub insert_dimension {
  my $self = shift;

  state $check = compile_named(
    dimension => Str,
    inherit   => Bool, { default => 0 }
  );
  my $p = $check->(@_);

  $self->batch_requests(
    insertDimension => {
      range             => $self->range_to_dimension($p->{dimension}),
      inheritFromBefore => $p->{inherit},
    },
  );

  return $self;
}

sub insert_r { shift->insert_dimension(dimension => shift); }
sub insert_range {
  my $self = shift;

  state $check = compile_named(
    dimension => Str,
  );
  my $p = $check->(@_);

  $self->batch_requests(
    insertRange    => {
      range => $self->range_to_dimension($p->{dimension}),
    },
    shiftDimension => $p->{dimension},
  );

  return $self;
}

sub move { shift->move_dimension(dimension => shift, destination => shift); }
sub move_dimension {
  my $self = shift;

  state $check = compile_named(
    dimension   => Str,
    destination => HasMethods['range_to_index'],
  );
  my $p = $check->(@_);

  $self->batch_requests(
    insertDimension => {
      range            => $self->range_to_dimension($p->{dimension}),
      destinationIndex => $p->{destination},
    },
  );

  return $self;
}

sub copy_paste {
  my $self = shift;

  state $check = compile_named(
    destination => HasMethods['range_to_index'],
    type        => Str, { default => 'normal' },
    orientation => Str, { default => 'normal' },
  );
  my $p = $check->(@_);
  $p->{type} = "PASTE_" . uc($p->{type});
  $p->{orientation} = uc($p->{orientation});

  $self->batch_requests(
    copyPaste => {
      source      => $self->range_to_index(),
      destination => $p->{destination}->range_to_index(),
      type        => $p->{type},
      orientation => $p->{orientation},
    },
  );

  return $self;
}

sub cut_paste {
  my $self = shift;

  state $check = compile_named(
    destination => HasMethods['range_to_index'],
    type        => Str, { default => 'normal' },
  );
  my $p = $check->(@_);
  $p->{type} = "PASTE_" . uc($p->{type});

  $self->batch_requests(
    cutPaste => {
      source      => $self->range_to_index(),
      destination => $p->{destination}->range_to_index(),
      type        => $p->{type},
    },
  );

  return $self;
}

sub delete_d { shift->delete_dimension(dimension => shift); }
sub delete_dimension {
  my $self = shift;

  state $check = compile_named(dimension => Str);
  my $p = $check->(@_);

  $self->batch_requests(
    deleteDimension => {
      range => $self->range_to_dimension($p->{dimension}),
    },
  );

  return $self;
}

sub delete_r { shift->delete_range(dimension => shift); }
sub delete_range {
  my $self = shift;

  state $check = compile_named(dimension => Str);
  my $p = $check->(@_);

  $self->batch_requests(
    deleteRange => {
      range => $self->range_to_dimension($p->{dimension}),
    },
    shiftDimension => $p->{dimension},
  );

  return $self;
}

sub named_a { shift->add_named(name => shift); }
sub add_named {
  my $self = shift;

  state $check = compile_named(name => Str);
  my $p = $check->(@_);

  $self->batch_requests(
    addNamedRange => {
      namedRange => {
        name  => $p->{name},
        range => $self->range_to_index(),
      },
    }
  );

  return $self;
}

sub named_d { shift->delete_named(); }
sub delete_named {
  my $self = shift;

  my $named = $self->named() or LOGDIE "Not a named range";
  $self->batch_requests(
    deleteNamedRange => {
      namedRangeId => $named,
    },
  );

  return $self;
}

sub _clear {
  my $self = shift;
  return $self->SUPER::_clear(@_, $self->range_to_index());
}

sub range_to_index { shift->range()->range_to_index(@_); }
sub range_to_dimension { shift->range()->range_to_dimension(@_); }

1;

__END__

=head1 NAME

Google::RestApi::SheetsApi4::Request::Spreadsheet::Worksheet::Range - Build Google API's batchRequests for a Range.

=head1 DESCRIPTION

Deriving from the Request::Spreadsheet::Worksheet object, this adds the ability to create
requests that have to do with ranges (formatting, borders etc).

See the description and synopsis at Google::RestApi::SheetsApi4::Request.
and Google::RestApi::SheetsApi4.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2021, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
