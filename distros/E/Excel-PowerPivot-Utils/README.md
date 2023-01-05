Excel::PowerPivot::Utils - utilities for scripting Power Pivot models within Excel workbooks

  use Excel::PowerPivot::Utils;
  my $ppu = Excel::PowerPivot::Utils->new; # will connect to the currently active workbook

  # operations on the whole model ...
  print $ppu->whole_model_as_YAML;
  $ppu->inject_whole_model({QUERIES       => ...,
                            RELATIONSHIPS => ...
                            MEASURES      => ...});

  # .. or specific operations on queries, relationships or measures
  print $ppu->queries_as_YAML;
  $ppu->inject_queries ([{Name => 'New_table', Formula => $M_formula_for_new_table}]);
  
  print $ppu->relationships_as_YAML;
  $ppu->inject_relationships([ {ForeignKey  => 'Album.ArtistId',
                                PrimaryKey  => 'Artist.ArtistId',
                                Active      => 1},
                               ...
                             ]);
  
  print $ppu->measures_as_YAML;
  $ppu->inject_measures([{Name              => 'Invoice Lines Total Amount',
                          AssociatedTable   => 'InvoiceLine',
                          Description       => 'sum of quantities multiplied by unit price',
                          FormatInformation => [qw/Currency  USD 2/],
                          Formula           => 'SUMX(InvoiceLine, InvoiceLine[UnitPrice] * InvoiceLine[Quantity]'
                         },
                         ...
                        ]);

This module uses OLE automation to interact with an Excel Power Pivot model.
It can be used for example for documenting existing models, or for scripting
series of updates or inserts on measures or queries as batch operations.


Obviously, this only works on a Windows platform with a local installation of
Microsoft Office 2016 or greater.

The exposed interface hides details about the interaction with the Excel object model documented in
L<https://learn.microsoft.com/en-us/office/vba/excel/concepts/about-the-powerpivot-model-object-in-excel>;
nevertheless, some knowledge of that model and of the L<Win32::OLE> module is recommended to fully understand
what is going on.
