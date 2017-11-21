package Linux::InitFS;
use warnings;
use strict;

use 5.10.0;

our $VERSION = 0.1;

use base 'Exporter';
our @EXPORT = qw( detect_kernel_config
                  enable_initfs_features
                  generate_initfs_spec
                  kernel_feature_enabled );

use Linux::InitFS::Entry;
use Linux::InitFS::Kernel;
use Linux::InitFS::Feature;


sub generate_initfs_spec {

	return Linux::InitFS::Entry->execute();
}

{
	no strict 'refs';

	*{'Linux::InitFS::detect_kernel_config'} = *{'Linux::InitFS::Kernel::detect_config'}{CODE};
	*{'Linux::InitFS::kernel_feature_enabled'} = *{'Linux::InitFS::Kernel::feature_enabled'}{CODE};
	*{'Linux::InitFS::enable_initfs_features'} = *{'Linux::InitFS::Feature::enable_features'}{CODE};

}

1;
