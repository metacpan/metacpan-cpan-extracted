%#----------------------------------------------------------------------------
%# brick: bricks_header_and_footer
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
        'data' => {
          'text' => '<link rel="stylesheet" type="text/css" href="/webnoir.css">
'
        },
        'name' => 'text'
      },
      {
        'data' => {
          'rprops' => {
            'height' => '100%',
            'cellpadding' => '0',
            'border' => '0',
            'width' => '100%',
            'cellspacing' => '0'
          },
          'rrows' => [
            [
              {
                'data' => {
                  'rcol' => [],
                  'rprops' => {
                    'width' => '100%'
                  }
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {
                        'text' => 'Bricks&nbsp;Site'
                      },
                      'name' => 'text'
                    }
                  ],
                  'rprops' => {
                    'class' => 'title',
                    'align' => 'right'
                  }
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {
                        'text' => '&nbsp;Builder'
                      },
                      'name' => 'text'
                    }
                  ],
                  'rprops' => {
                    'class' => 'title'
                  }
                },
                'name' => 'column'
              }
            ],
            [
              {
                'data' => {
                  'rcol' => [],
                  'rprops' => {}
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {
                        'text' => 'It\'s&nbsp;the&nbsp;kick'
                      },
                      'name' => 'text'
                    }
                  ],
                  'rprops' => {
                    'class' => 'subtitle',
                    'align' => 'right'
                  }
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {
                        'text' => '-assest'
                      },
                      'name' => 'text'
                    }
                  ],
                  'rprops' => {
                    'class' => 'subtitle'
                  }
                },
                'name' => 'column'
              }
            ],
            [
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {
                        'frozen_filelink' => {
                          'data' => {
                            'load' => 0,
                            'data' => 'This is index.html.
<p>
You should not see this if Bricks Site Builder has been correctly installed.
<p>

This is edited text',
                            'frozen_file_open' => {
                              'data' => {
                                'folder_mode' => 'list',
                                'path' => '',
                                'rtypes' => [
                                  [
                                    '.*',
                                    'all files'
                                  ]
                                ],
                                'name' => '',
                                'rdests' => [
                                  '/'
                                ],
                                'filter' => '.*',
                                'type' => 'open'
                              },
                              'name' => 'fileselect'
                            },
                            'return' => undef,
                            'frozen_file_save_as' => {
                              'data' => {
                                'folder_mode' => 'list',
                                'path' => '',
                                'rtypes' => [
                                  [
                                    '.*',
                                    'all files'
                                  ]
                                ],
                                'name' => '',
                                'rdests' => [
                                  '/'
                                ],
                                'filter' => '.*',
                                'type' => 'save_as'
                              },
                              'name' => 'fileselect'
                            },
                            'filename' => '/index.html'
                          },
                          'name' => 'filelink'
                        }
                      },
                      'name' => 'next'
                    }
                  ],
                  'rprops' => {
                    'height' => '600',
                    'valign' => 'top',
                    'width' => '100%',
                    'colspan' => '3',
                    'bgcolor' => '#666666'
                  }
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [],
                  'rprops' => {}
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [],
                  'rprops' => {}
                },
                'name' => 'column'
              }
            ],
            [
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {
                        'rprops' => {
                          'width' => '100%'
                        },
                        'rrows' => [
                          [
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {},
                                    'name' => 'version'
                                  }
                                ],
                                'rprops' => {
                                  'width' => '1'
                                }
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {
                                      'start_year' => '2001',
                                      'dpy_cright' => '&copy;&nbsp;',
                                      'dpy_cent' => 'on'
                                    },
                                    'name' => 'copyright'
                                  }
                                ],
                                'rprops' => {
                                  'align' => 'center'
                                }
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {
                                      'text' => '<a href="http://www.sourceforge.net/projects/bricks">http://www.sourceforge.net/projects/bricks</a>'
                                    },
                                    'name' => 'text'
                                  }
                                ],
                                'rprops' => {
                                  'width' => '1',
                                  'align' => 'right'
                                }
                              },
                              'name' => 'column'
                            }
                          ]
                        ],
                        'ncols' => 3,
                        'nrows' => 1
                      },
                      'name' => 'table'
                    }
                  ],
                  'rprops' => {
                    'height' => '100%',
                    'valign' => 'bottom',
                    'colspan' => '3'
                  }
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [],
                  'rprops' => {}
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [],
                  'rprops' => {}
                },
                'name' => 'column'
              }
            ]
          ],
          'ncols' => '3',
          'nrows' => 4
        },
        'name' => 'table'
      }
    ],
    'rprops' => {
      'use_props' => 'self',
      'title' => 'Bricks Site Builder',
      'body' => 'bgcolor="gray"',
      'doctype' => undef
    },
    'prev_modified_defined' => -1,
    'mode' => undef,
    'frozen_file_save_as' => {
      'data' => {
        'folder_mode' => 'list',
        'path' => '/user',
        'rtypes' => [
          [
            '.*',
            'all files'
          ]
        ],
        'name' => 'bricks_header_and_footer.mc',
        'rdests' => [
          '/'
        ],
        'filter' => '.*',
        'type' => 'save_as'
      },
      'name' => 'fileselect'
    }
  },
  'name' => 'bricks_header_and_footer'
};
</%once>
