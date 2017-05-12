use strict;
use warnings;
use Test::More tests => 2;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;
my $form = HTML::FormFu->new;

$form->load_config_file('t/options_from_model/belongs_to_combobox.yml');

my $schema = new_schema();

$form->stash->{schema} = $schema;

my $type_rs  = $schema->resultset('Type');
my $type2_rs = $schema->resultset('Type2');

{

    # types
    $type_rs->delete;
    $type_rs->create( { type => 'type 1' } );
    $type_rs->create( { type => 'type 2' } );
    $type_rs->create( { type => 'type 3' } );

    $type2_rs->delete;
    $type2_rs->create( { type => 'type 1' } );
    $type2_rs->create( { type => 'type 2' } );
    $type2_rs->create( { type => 'type 3' } );
}

$form->process;

is(
  $form->get_field('type'),
  qq{<div>
<span class="elements">
<select name="type_select">
<option value=""></option>
<option value="1">type 1</option>
<option value="2">type 2</option>
<option value="3">type 3</option>
</select>
<input name="type_text" type="text" />
</span>
</div>}
);

is(
  $form->get_field('type2_id'),
  qq{<div>
<span class="elements">
<select name="type2_id_select">
<option value=""></option>
<option value="1">type 1</option>
<option value="2">type 2</option>
<option value="3">type 3</option>
</select>
<input name="type2_id_text" type="text" />
</span>
</div>}
);
