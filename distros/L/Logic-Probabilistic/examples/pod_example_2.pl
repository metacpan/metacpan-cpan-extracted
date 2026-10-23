use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

prob_logic SensorFusion {
    pfact 0.20 => sensor_alarm('cam1');
    pfact 0.15 => sensor_alarm('radar');

    rule intruder {
        sensor_alarm('cam1');
        sensor_alarm('radar');
    }
}

# 1. Query initial state
query_prob SensorFusion::intruder -> my $res1;
say "Initial P(intruder): $res1"; # ~0.0300

# 2. Dynamically update camera sensor reading using $SensorFusion::PROGRAM
$SensorFusion::PROGRAM->update_pfact(0.95, 'sensor_alarm', 'cam1');

# 3. Upsert a new acoustic sensor reading
$SensorFusion::PROGRAM->set_pfact(0.80, 'sensor_alarm', 'acoustic');

# 4. Query again - reflecting the updated sensor probabilities
query_prob SensorFusion::intruder -> my $res2;
say "Updated P(intruder): $res2"; # ~0.1425


