use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::BCM2835',
    VERSION_FROM      => 'lib/Device/BCM2835.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Device/BCM2835.pm', # retrieve abstract from module
    AUTHOR            => 'Mike McCauley <mikem@airspayce.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS              => ['-L/usr/local/projects/bcm2835/src -lbcm2835 -lrt'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I/usr/local/projects/bcm2835/src', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(BCM2835_BLOCK_SIZE BCM2835_BSC0_BASE BCM2835_BSC1_BASE
		 BCM2835_BSC_A BCM2835_BSC_C BCM2835_BSC_CLKT
		 BCM2835_BSC_C_CLEAR_1 BCM2835_BSC_C_CLEAR_2
		 BCM2835_BSC_C_I2CEN BCM2835_BSC_C_INTD BCM2835_BSC_C_INTR
		 BCM2835_BSC_C_INTT BCM2835_BSC_C_READ BCM2835_BSC_C_ST
		 BCM2835_BSC_DEL BCM2835_BSC_DIV BCM2835_BSC_DLEN
		 BCM2835_BSC_FIFO BCM2835_BSC_FIFO_SIZE BCM2835_BSC_S
		 BCM2835_BSC_S_CLKT BCM2835_BSC_S_DONE BCM2835_BSC_S_ERR
		 BCM2835_BSC_S_RXD BCM2835_BSC_S_RXF BCM2835_BSC_S_RXR
		 BCM2835_BSC_S_TA BCM2835_BSC_S_TXD BCM2835_BSC_S_TXE
		 BCM2835_BSC_S_TXW BCM2835_CLOCK_BASE BCM2835_CORE_CLK_HZ
		 BCM2835_GPAFEN0 BCM2835_GPAFEN1 BCM2835_GPAREN0
		 BCM2835_GPAREN1 BCM2835_GPCLR0 BCM2835_GPCLR1 BCM2835_GPEDS0
		 BCM2835_GPEDS1 BCM2835_GPFEN0 BCM2835_GPFEN1 BCM2835_GPFSEL0
		 BCM2835_GPFSEL1 BCM2835_GPFSEL2 BCM2835_GPFSEL3
		 BCM2835_GPFSEL4 BCM2835_GPFSEL5 BCM2835_GPHEN0 BCM2835_GPHEN1
		 BCM2835_GPIO_BASE BCM2835_GPIO_PADS BCM2835_GPIO_PWM
		 BCM2835_GPLEN0 BCM2835_GPLEN1 BCM2835_GPLEV0 BCM2835_GPLEV1
		 BCM2835_GPPUD BCM2835_GPPUDCLK0 BCM2835_GPPUDCLK1
		 BCM2835_GPREN0 BCM2835_GPREN1 BCM2835_GPSET0 BCM2835_GPSET1
		 BCM2835_PADS_GPIO_0_27 BCM2835_PADS_GPIO_28_45
		 BCM2835_PADS_GPIO_46_53 BCM2835_PAD_DRIVE_10mA
		 BCM2835_PAD_DRIVE_12mA BCM2835_PAD_DRIVE_14mA
		 BCM2835_PAD_DRIVE_16mA BCM2835_PAD_DRIVE_2mA
		 BCM2835_PAD_DRIVE_4mA BCM2835_PAD_DRIVE_6mA
		 BCM2835_PAD_DRIVE_8mA BCM2835_PAD_HYSTERESIS_ENABLED
		 BCM2835_PAD_PASSWRD BCM2835_PAD_SLEW_RATE_UNLIMITED
		 BCM2835_PAGE_SIZE BCM2835_PERI_BASE BCM2835_PERI_SIZE
		 BCM2835_PWM0_DATA BCM2835_PWM0_ENABLE BCM2835_PWM0_MS_MODE
		 BCM2835_PWM0_OFFSTATE BCM2835_PWM0_RANGE BCM2835_PWM0_REPEATFF
		 BCM2835_PWM0_REVPOLAR BCM2835_PWM0_SERIAL BCM2835_PWM0_USEFIFO
		 BCM2835_PWM1_DATA BCM2835_PWM1_ENABLE BCM2835_PWM1_MS_MODE
		 BCM2835_PWM1_OFFSTATE BCM2835_PWM1_RANGE BCM2835_PWM1_REPEATFF
		 BCM2835_PWM1_REVPOLAR BCM2835_PWM1_SERIAL BCM2835_PWM1_USEFIFO
		 BCM2835_PWMCLK_CNTL BCM2835_PWMCLK_DIV BCM2835_PWM_CLEAR_FIFO
		 BCM2835_PWM_CONTROL BCM2835_PWM_DMAC BCM2835_PWM_FIF1
		 BCM2835_PWM_PASSWRD BCM2835_PWM_STATUS BCM2835_SPI0_BASE
		 BCM2835_SPI0_CLK BCM2835_SPI0_CS BCM2835_SPI0_CS_ADCS
		 BCM2835_SPI0_CS_CLEAR BCM2835_SPI0_CS_CLEAR_RX
		 BCM2835_SPI0_CS_CLEAR_TX BCM2835_SPI0_CS_CPHA
		 BCM2835_SPI0_CS_CPOL BCM2835_SPI0_CS_CS BCM2835_SPI0_CS_CSPOL
		 BCM2835_SPI0_CS_CSPOL0 BCM2835_SPI0_CS_CSPOL1
		 BCM2835_SPI0_CS_CSPOL2 BCM2835_SPI0_CS_DMAEN
		 BCM2835_SPI0_CS_DMA_LEN BCM2835_SPI0_CS_DONE
		 BCM2835_SPI0_CS_INTD BCM2835_SPI0_CS_INTR BCM2835_SPI0_CS_LEN
		 BCM2835_SPI0_CS_LEN_LONG BCM2835_SPI0_CS_LMONO
		 BCM2835_SPI0_CS_REN BCM2835_SPI0_CS_RXD BCM2835_SPI0_CS_RXF
		 BCM2835_SPI0_CS_RXR BCM2835_SPI0_CS_TA BCM2835_SPI0_CS_TE_EN
		 BCM2835_SPI0_CS_TXD BCM2835_SPI0_DC BCM2835_SPI0_DLEN
		 BCM2835_SPI0_FIFO BCM2835_SPI0_LTOH BCM2835_ST_BASE
		 BCM2835_ST_CHI BCM2835_ST_CLO BCM2835_ST_CS BCM2835_VERSION
		 BMC2835_RPI2_DT_PERI_BASE_ADDRESS_OFFSET
		 BMC2835_RPI2_DT_PERI_SIZE_OFFSET HIGH LOW),
              {name=>"BCM2835_GPIO_FSEL_ALT0", macro=>"1"},
              {name=>"BCM2835_GPIO_FSEL_ALT1", macro=>"1"},
              {name=>"BCM2835_GPIO_FSEL_ALT2", macro=>"1"},
              {name=>"BCM2835_GPIO_FSEL_ALT3", macro=>"1"},
              {name=>"BCM2835_GPIO_FSEL_ALT4", macro=>"1"},
              {name=>"BCM2835_GPIO_FSEL_ALT5", macro=>"1"},
              {name=>"BCM2835_GPIO_FSEL_INPT", macro=>"1"},
              {name=>"BCM2835_GPIO_FSEL_MASK", macro=>"1"},
              {name=>"BCM2835_GPIO_FSEL_OUTP", macro=>"1"},
              {name=>"BCM2835_GPIO_PUD_DOWN", macro=>"1"},
              {name=>"BCM2835_GPIO_PUD_OFF", macro=>"1"},
              {name=>"BCM2835_GPIO_PUD_UP", macro=>"1"},
              {name=>"BCM2835_I2C_CLOCK_DIVIDER_148", macro=>"1"},
              {name=>"BCM2835_I2C_CLOCK_DIVIDER_150", macro=>"1"},
              {name=>"BCM2835_I2C_CLOCK_DIVIDER_2500", macro=>"1"},
              {name=>"BCM2835_I2C_CLOCK_DIVIDER_626", macro=>"1"},
              {name=>"BCM2835_I2C_REASON_ERROR_CLKT", macro=>"1"},
              {name=>"BCM2835_I2C_REASON_ERROR_DATA", macro=>"1"},
              {name=>"BCM2835_I2C_REASON_ERROR_NACK", macro=>"1"},
              {name=>"BCM2835_I2C_REASON_OK", macro=>"1"},
              {name=>"BCM2835_PAD_GROUP_GPIO_0_27", macro=>"1"},
              {name=>"BCM2835_PAD_GROUP_GPIO_28_45", macro=>"1"},
              {name=>"BCM2835_PAD_GROUP_GPIO_46_53", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_1", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_1024", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_128", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_16", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_2", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_2048", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_256", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_32", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_4", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_512", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_64", macro=>"1"},
              {name=>"BCM2835_PWM_CLOCK_DIVIDER_8", macro=>"1"},
              {name=>"BCM2835_REGBASE_BSC0", macro=>"1"},
              {name=>"BCM2835_REGBASE_BSC1", macro=>"1"},
              {name=>"BCM2835_REGBASE_CLK", macro=>"1"},
              {name=>"BCM2835_REGBASE_GPIO", macro=>"1"},
              {name=>"BCM2835_REGBASE_PADS", macro=>"1"},
              {name=>"BCM2835_REGBASE_PWM", macro=>"1"},
              {name=>"BCM2835_REGBASE_SPI0", macro=>"1"},
              {name=>"BCM2835_REGBASE_ST", macro=>"1"},
              {name=>"BCM2835_SPI_BIT_ORDER_LSBFIRST", macro=>"1"},
              {name=>"BCM2835_SPI_BIT_ORDER_MSBFIRST", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_1", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_1024", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_128", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_16", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_16384", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_2", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_2048", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_256", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_32", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_32768", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_4", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_4096", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_512", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_64", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_65536", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_8", macro=>"1"},
              {name=>"BCM2835_SPI_CLOCK_DIVIDER_8192", macro=>"1"},
              {name=>"BCM2835_SPI_CS0", macro=>"1"},
              {name=>"BCM2835_SPI_CS1", macro=>"1"},
              {name=>"BCM2835_SPI_CS2", macro=>"1"},
              {name=>"BCM2835_SPI_CS_NONE", macro=>"1"},
              {name=>"BCM2835_SPI_MODE0", macro=>"1"},
              {name=>"BCM2835_SPI_MODE1", macro=>"1"},
              {name=>"BCM2835_SPI_MODE2", macro=>"1"},
              {name=>"BCM2835_SPI_MODE3", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_03", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_05", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_07", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_08", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_10", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_11", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_12", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_13", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_15", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_16", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_18", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_19", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_21", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_22", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_23", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_24", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_26", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_29", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_31", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_32", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_33", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_35", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_36", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_37", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_38", macro=>"1"},
              {name=>"RPI_BPLUS_GPIO_J8_40", macro=>"1"},
              {name=>"RPI_GPIO_P1_03", macro=>"1"},
              {name=>"RPI_GPIO_P1_05", macro=>"1"},
              {name=>"RPI_GPIO_P1_07", macro=>"1"},
              {name=>"RPI_GPIO_P1_08", macro=>"1"},
              {name=>"RPI_GPIO_P1_10", macro=>"1"},
              {name=>"RPI_GPIO_P1_11", macro=>"1"},
              {name=>"RPI_GPIO_P1_12", macro=>"1"},
              {name=>"RPI_GPIO_P1_13", macro=>"1"},
              {name=>"RPI_GPIO_P1_15", macro=>"1"},
              {name=>"RPI_GPIO_P1_16", macro=>"1"},
              {name=>"RPI_GPIO_P1_18", macro=>"1"},
              {name=>"RPI_GPIO_P1_19", macro=>"1"},
              {name=>"RPI_GPIO_P1_21", macro=>"1"},
              {name=>"RPI_GPIO_P1_22", macro=>"1"},
              {name=>"RPI_GPIO_P1_23", macro=>"1"},
              {name=>"RPI_GPIO_P1_24", macro=>"1"},
              {name=>"RPI_GPIO_P1_26", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_03", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_05", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_07", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_08", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_10", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_11", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_12", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_13", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_15", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_16", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_18", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_19", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_21", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_22", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_23", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_24", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_26", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_29", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_31", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_32", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_33", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_35", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_36", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_37", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_38", macro=>"1"},
              {name=>"RPI_V2_GPIO_P1_40", macro=>"1"},
              {name=>"RPI_V2_GPIO_P5_03", macro=>"1"},
              {name=>"RPI_V2_GPIO_P5_04", macro=>"1"},
              {name=>"RPI_V2_GPIO_P5_05", macro=>"1"},
              {name=>"RPI_V2_GPIO_P5_06", macro=>"1"});
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Device::BCM2835',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
