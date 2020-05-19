use Test::More;
use File::Groups;

for my $category (qw(word_processing spreadsheet video image graphics_editor)) {
  isa_ok(File::Groups->$category->extensions, 'ARRAY', $category);
  ok(scalar @{File::Groups->$category->extensions} > 1, $category);
  ok(scalar @{File::Groups->$category->extensions} < scalar @{File::Groups->$category->extensions(1)}, "$category all");

  isa_ok(File::Groups->$category->media_types, 'ARRAY', $category);
  ok(scalar @{File::Groups->$category->media_types} > 1, $category);
  ok(scalar @{File::Groups->$category->media_types} <= scalar @{File::Groups->$category->media_types(1)}, "$category all");
}

for my $category (qw(project_management presentation)) {
  isa_ok(File::Groups->$category->extensions, 'ARRAY', $category);
  ok(scalar @{File::Groups->$category->extensions} > 1, $category);

  isa_ok(File::Groups->$category->media_types, 'ARRAY', $category);
  ok(scalar @{File::Groups->$category->media_types} >= 1, $category);
}

isa_ok(File::Groups->spreadsheet->excel->media_types, 'ARRAY');
ok(scalar @{File::Groups->spreadsheet->excel->media_types} > 1);

isa_ok(File::Groups->spreadsheet->excel->extensions, 'ARRAY');
ok(scalar @{File::Groups->spreadsheet->excel->extensions} > 1);

isa_ok(File::Groups->image->raster->media_types, 'ARRAY');
isa_ok(File::Groups->image->raster->extensions, 'ARRAY');

ok(scalar @{File::Groups->image->raster->media_types} > 1);
ok(scalar @{File::Groups->image->raster->extensions} > 1);

ok(scalar @{File::Groups->image->raster->media_types} < scalar @{File::Groups->image->raster->media_types(1)});
ok(scalar @{File::Groups->image->raster->extensions} < scalar @{File::Groups->image->raster->extensions(1)});

done_testing();
