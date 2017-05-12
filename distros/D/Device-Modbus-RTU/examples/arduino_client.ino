/*********************************************
     Test for Device::Modbus RTU server 
     2015-09-07
 **********************************************/

void setup() {
    Serial.begin(9600);
}

void loop() {
    // Send a valid request
    uint8_t a[8] = {3,3,0,2,0,1,36,40};
    int i;
    for (i = 0; i < 8; i++) {
      Serial.write(a[i]);
    }
    
    delay(1000);
}
