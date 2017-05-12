package Device::WallyHome::Test::Data;
use Moose;
use namespace::autoclean;

our $VERSION = '0.21.3';


#== PUBLIC METHODS =============================================================

sub sampleResponse_places_1 {
    return q|
        [
            {
                "id": "abcdef01234",
                "accountId": "000-111-222-3333-44-5555",
                "label": "Wally Labs",
                "fullAddress": {
                    "line1": "Office",
                    "line2": "1415 NE 45th St",
                    "city": "Seattle",
                    "state": "WA",
                    "zip": "98105"
                },
                "address": "Office, 1415 NE 45th St, Seattle, WA 98105",
                "suspended": false,
                "buzzerEnabled": true,
                "sensorIds": ["90-7a-f1-ff-ff-ff"],
                "nestAdjustments": {},
                "nestEnabled": true,
                "rapidResponseSupport": ["rapidResponseSupport"]
        } ]
    |;
}

sub sampleResponse_sensors_1 {
    return q|
        [
           {
              "snid":"90-7a-f1-ff-ff-ff",
              "offline":false,
              "suspended":false,
              "paired":"2016-07-06T17:11:58.001Z",
              "updated":"2016-07-06T20:48:35.872Z",
              "alarmed":false,
              "signalStrength":0,
              "recentSignalStrength":55.737163247999995,
              "hardwareType":"FourInOneSensor",
              "location":{
                 "id":"00003bd0c9e77c0021fc60e1",
                 "placeId":"abcdef01234",
                 "sensorId":"90-7a-f1-ff-ff-ff",
                 "room":"Kitchen",
                 "appliance":"Sink",
                 "floor":"Main Floor",
                 "functionalType":"LEAK",
                 "created":"2016-07-06T17:11:44.926Z",
                 "updated":"2016-07-06T17:11:44.920Z"
              },
              "thresholds":{
                 "TEMP":{
                    "name":"TEMP",
                    "min":10,
                    "max":38
                 },
                 "RH":{
                    "name":"RH",
                    "min":30
                 }
              },
              "state":{
                 "RH":{
                    "value":56,
                    "at":"2016-07-06T20:48:35.315Z"
                 },
                 "TEMP":{
                    "value":21,
                    "at":"2016-07-06T20:48:35.315Z"
                 },
                 "LEAK":{
                    "value":0,
                    "at":"2016-07-06T20:48:35.315Z"
                 },
                 "SENSOR":{
                    "value":0,
                    "at":"2016-07-06T20:48:35.315Z"
                 },
                 "COND":{
                    "value":0,
                    "at":"2016-07-06T20:48:35.315Z"
                 }
              },
              "activities":[
                 {
                    "snid":"90-7a-f1-ff-ff-ff",
                    "created":"2014-10-13T21:37:36.472Z",
                    "type":"alarm",
                    "state":"open",
                    "viewParams":{
                       "floor":"Main Floor",
                       "location":"Main Floor Kitchen Sink",
                       "label":"Wally Labs",
                       "appliance":"Sink",
                       "room":"Kitchen"
                    }
                 }
              ]
           }
        ]
    |;
}


__PACKAGE__->meta->make_immutable;

1;
