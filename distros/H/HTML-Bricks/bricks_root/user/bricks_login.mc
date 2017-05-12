%#----------------------------------------------------------------------------
%# brick: bricks_login
%#
%# from here to "once" tag from /bricks/assembly_template
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my $rbrick = shift;
  $rbrick->push_supers('assembly');
  $rbrick->super->new();
  $rbrick->thaw($rsaved_node1);
</%perl>
</%method>

%#----------------------------------------------------------------------------
%# dont_list
%#----------------------------------------------------------------------------
<%method dont_list>
<%perl>
  
  # if this method exists, this brick name will not be returned by 
  # HTML::Bricks::get_bricks_list

</%perl>
</%method>

%#---------------------------------------------------------------------------
%# thaw
%#---------------------------------------------------------------------------
<%method thaw>
<%perl>
  my ($rbrick, $rnode)  = @_;

  $rbrick->push_supers('assembly');
  $rbrick->super->new();

  my $rnode_data = $$rnode{data};
  
  if (exists $$rnode_data{rcol}) { 
    #
    # If we're passed in an actual frozen assembly, then thaw what's
    # passed in, else thaw the copy in this file
    #
 
    return $rbrick->super->thaw($rnode);
  }

  return $rbrick->super->thaw($rsaved_node1);
</%perl>
</%method>

%#---------------------------------------------------------------------------
%# is_assembly
%#---------------------------------------------------------------------------
<%method is_assembly>
<%perl>
  return 1;
</%perl>
</%method>

%#---------------------------------------------------------------------------
%# once
%#---------------------------------------------------------------------------
<%once>
  my $rsaved_node1 = {
  'data' => {
    'rcol' => [
      {
        'data' => {},
        'name' => 'useraccess'
      }
    ],
    'rprops' => {},
    'modified' => 0,
    'mode' => undef,
    'frozen_file_save_as' => {
      'data' => {
        'path' => '/user',
        'folder_mode' => 'list',
        'rtypes' => [
          [
            '.*',
            'all files'
          ]
        ],
        'name' => 'bricks_login.mc',
        'rfilename' => \'/user/bricks_login.mc',
        'rdests' => [
          '/'
        ],
        'rreturn' => \undef,
        'filter' => '.*',
        'type' => undef
      },
      'name' => 'fileselect'
    }
  },
  'name' => 'bricks_login'
};
</%once>
