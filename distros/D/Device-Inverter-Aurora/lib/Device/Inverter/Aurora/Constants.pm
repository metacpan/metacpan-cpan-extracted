package Device::Inverter::Aurora;

use constant OP_GET_STATE                   => 50;
use constant OP_GET_PART_NUMBER             => 52;
use constant OP_GET_VERSION                 => 58;
use constant OP_GET_DSP                     => 59;
use constant OP_GET_SERIAL_NUMBER           => 63;
use constant OP_GET_MANUFACTURING_DATE      => 65;
use constant OP_GET_TIME                    => 70;
use constant OP_SET_TIME                    => 71;
use constant OP_GET_FIRMWARE_VERSION        => 72;
use constant OP_GET_LAST_10_SEC_ENERGY      => 76;
use constant OP_GET_CONFIGURATION           => 77;
use constant OP_GET_CUMULATED_ENERGY        => 78;
use constant OP_GET_COUNTERS                => 80;
use constant OP_GET_LAST_4_ALARMS           => 86;

use constant CUMULATED_DAILY                => 0;
use constant CUMULATED_WEEKLY               => 1;
use constant CUMULATED_MONTHLY              => 3;
use constant CUMULATED_YEARLY               => 4;
use constant CUMULATED_TOTAL                => 5;
use constant CUMULATED_PARTIAL              => 6;

use constant DSP_GRID_VOLTAGE               => 1;   # Grid Voltage (Global)
use constant DSP_GRID_CURRENT               => 2;   # Grid Current (Global)
use constant DSP_GRID_POWER                 => 3;   # Grid Power (Global)
use constant DSP_FREQUENCY                  => 4;   # Frequency
use constant DSP_VBULK                      => 5;   # VBulk
use constant DSP_ILEAK_DCDC                 => 6;   # Ileak (Dc/Dc)
use constant DSP_ILEAK_INVERTER             => 7;   # Ileak (Inverter)
use constant DSP_PIN_1                      => 8;   # Pin 1 (Global)
use constant DSP_PIN_2                      => 9;   # Pin 2
use constant DSP_INVERTER_TEMPERATURE       => 21;  # Inverter Temperature
use constant DSP_BOOSTER_TEMPERATURE        => 22;  # Booster Temperature
use constant DSP_INPUT_1_VOLTAGE            => 23;  # Input 1 Voltage
use constant DSP_INPUT_1_CURRENT            => 25;  # Input 1 Current
use constant DSP_INPUT_2_VOLTAGE            => 26;  # Input 2 Voltage
use constant DSP_INPUT_2_CURRENT            => 27;  # Input 2 Current
use constant DSP_GRID_VOLTAGE_DCDC          => 28;  # Grid Voltage (Dc/Dc)
use constant DSP_GRID_FREQUENCY_DCDC        => 29;  # Grid Frequency (Dc/Dc)
use constant DSP_ISOLATION_RESISTANCE       => 30;  # Isolation Resistance (Riso)
use constant DSP_VBULK_DCDC                 => 31;  # Vbulk (Dc/Dc)
use constant DSP_AVERAGE_GRID_VOLTAGE       => 32;  # Average Grid Voltage (VgridAvg)
use constant DSP_VBULK_MID                  => 33;  # Vbulk Mid
use constant DSP_POWER_PEAK                 => 34;  # Power Peak
use constant DSP_POWER_PEAK_TODAY           => 35;  # Power Peak Today
use constant DSP_GRID_VOLTAGE_NEUTRAL       => 36;  # Grid Voltage neutral
use constant DSP_WIND_GENERATOR_FREQUENCY   => 37;  # Wind Generator Frequency
use constant DSP_GRID_VOLTAGE_NEUTRAL_PHASE => 38;  # Grid Voltage neutral-phase
use constant DSP_GRID_CURRENT_PHASE_R       => 39;  # Grid Current phase r
use constant DSP_GRID_CURRENT_PHASE_S       => 40;  # Grid Current phase s
use constant DSP_GRID_CURRENT_PHASE_T       => 41;  # Grid Current phase t
use constant DSP_FREQUENCY_PHASE_R          => 32;  # Frequency phase r
use constant DSP_FREQUENCY_PHASE_S          => 43;  # Frequency phase s
use constant DSP_FREQUENCY_PHASE_T          => 44;  # Frequency phase t
use constant DSP_VBULK_POSITIVE             => 45;  # Vbulk +
use constant DSP_VBULK_NEGATIVE             => 46;  # Vbulk -
use constant DSP_SUPERVISOR_TEMPERATURE     => 47;  # Supervisor Temperature
use constant DSP_ALIM_TEMPERATURE           => 48;  # Alim Temperature
use constant DSP_HEAT_SINK_TEMPERATURE      => 49;  # Heat Sink Temperature
use constant DSP_TEMPERATURE_1              => 50;  # Temperature 1
use constant DSP_TEMPERATURE_2              => 51;  # Temperature 2
use constant DSP_TEMPERATURE_3              => 52;  # Temperature 3
use constant DSP_FAN_1_SPEED                => 53;  # Fan 1 Speed
use constant DSP_FAN_2_SPEED                => 54;  # Fan 2 Speed
use constant DSP_FAN_3_SPEED                => 55;  # Fan 3 Speed
use constant DSP_FAN_4_SPEED                => 56;  # Fan 4 Speed
use constant DSP_FAN_5_SPEED                => 57;  # Fan 5 Speed
use constant DSP_POWER_SATURATION_LIMIT     => 58;  # Power Saturation Limit (Der.)
use constant DSP_RIFERIMENTO_ANELLO_BULK    => 59;  # Refeimento Anello Bulk
use constant DSP_VPANEL_MICRO               => 60;  # Vpanel micro
use constant DSP_GRID_VOLTAGE_PHASE_R       => 61;  # Grid Voltage phase r
use constant DSP_GRID_VOLTAGE_PHASE_S       => 62;  # Grid Voltage phase s
use constant DSP_GRID_VOLTAGE_PHASE_T       => 63;  # Grid Voltage phase t

use constant COUNTER_TOTAL                  => 0;
use constant COUNTER_PARTIAL                => 1;
use constant COUNTER_GRID                   => 2;
use constant COUNTER_RESET                  => 3;


1;
